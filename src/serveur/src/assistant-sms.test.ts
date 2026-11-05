import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { ComptesService } from "./modules/comptes/comptes.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const JOUR_MS = 24 * 60 * 60 * 1000;

/** SMS de l'assistant reçus par un membre (hors code de connexion), une fois la file vidée. */
async function smsDe(qui: Identite): Promise<string[]> {
  await app.get(FileSms).vider();
  const numero = (await app.get(ComptesService).chercher(qui.id))!.numero;
  return app
    .get<ConnecteurSmsSimule>(CONNECTEUR_SMS)
    .messages.filter((m) => m.numero === numero && !/code est/.test(m.texte))
    .map((m) => m.texte);
}

/** Cercle de trois avec un rappel la veille ; rend un payeur du premier tour et la date limite de ce tour. */
async function cercle(mode: "autonome" | "manuel") {
  const { membres, org, cercle } = await cercleComplet(client, reglementDeTest({ rappelsAvantEcheanceJours: [1] }));
  if (mode === "autonome") {
    await client.requete("POST", `/assistant/cercles/${cercle.id}/mode`, { mode: "autonome" }, org);
  }
  const beneficiaire = cercle.ordre![0]!.membreId;
  const payeur = membres.find((m) => m.id !== beneficiaire)!;
  const c1 = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1)!;
  const journal = async () =>
    (await (await client.requete("GET", `/assistant/cercles/${cercle.id}/journal`, undefined, org)).json()) as {
      id: string;
      type: string;
      membreId: string;
    }[];
  const accepter = (id: string) => client.requete("POST", `/assistant/propositions/${id}/acceptation`, undefined, org);
  return { org, cercle, payeur, c1, journal, accepter, planificateur: app.get(PlanificateurService) };
}

describe("l'assistant prévient les membres par SMS", () => {
  it("mode autonome : rappel la veille, avec le montant et la date limite ; examen rejoué, un seul SMS", async () => {
    const { payeur, c1, planificateur } = await cercle("autonome");
    const veille = new Date(Date.parse(c1.dateLimite) - JOUR_MS);
    await planificateur.examinerEcheances(veille);
    await planificateur.examinerEcheances(veille);
    const recus = await smsDe(payeur);
    expect(recus).toHaveLength(1);
    expect(recus[0]).toMatch(/rappel/i);
    expect(recus[0]).toContain("10 000 FCFA");
    expect(recus[0]).toContain("tour 1");
  });

  it("rappel de retard : payer avant la fin de grâce pour éviter un défaut", async () => {
    const { payeur, c1, planificateur } = await cercle("autonome");
    await planificateur.examinerEcheances(new Date(Date.parse(c1.dateLimite) + JOUR_MS));
    const [sms] = await smsDe(payeur);
    expect(sms).toMatch(/retard/);
    expect(sms).toMatch(/défaut/);
  });

  it("mise en demeure : le montant total dû (cotisation et pénalité)", async () => {
    const { cercle: c, payeur, c1, planificateur } = await cercle("autonome");
    await planificateur.constaterDefaut(c.id, payeur.id, 1, new Date(Date.parse(c1.finGrace) + 1000));
    const recus = await smsDe(payeur);
    expect(recus).toHaveLength(1);
    expect(recus[0]).toMatch(/mise en demeure/i);
    expect(recus[0]).toContain("10 500 FCFA");
  });

  it("mode manuel : rien ne part avant l'accord de l'organisateur, puis le SMS part", async () => {
    const { payeur, c1, journal, accepter, planificateur } = await cercle("manuel");
    await planificateur.examinerEcheances(new Date(Date.parse(c1.dateLimite) - JOUR_MS));
    expect(await smsDe(payeur)).toEqual([]);
    const proposition = (await journal()).find((a) => a.membreId === payeur.id)!;
    await accepter(proposition.id);
    expect(await smsDe(payeur)).toHaveLength(1);
  });

  it("rappel accepté après que le membre a déjà déclaré son paiement : aucun SMS inutile", async () => {
    const { payeur, c1, journal, accepter, planificateur } = await cercle("manuel");
    await planificateur.examinerEcheances(new Date(Date.parse(c1.dateLimite) - JOUR_MS));
    await client.requete("POST", `/cotisations/${c1.id}/paiement`, { referenceTransaction: "OM-9" }, payeur);
    const proposition = (await journal()).find((a) => a.membreId === payeur.id)!;
    await accepter(proposition.id);
    expect(await smsDe(payeur)).toEqual([]);
  });
});
