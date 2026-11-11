import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const HEURE_MS = 60 * 60 * 1000;

/** Premier tour : le payeur a déclaré son paiement, le bénéficiaire ne confirme pas. */
async function paiementDeclare() {
  const { membres, cercle } = await cercleComplet(client);
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const payeur = membres.find((m) => m !== beneficiaire) as Identite;
  const cotisation = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1)!;
  await client.requete("POST", `/cotisations/${cotisation.id}/paiement`, { referenceTransaction: "OM-77" }, payeur);
  const declareeLe = Date.parse(
    (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1)!.declareeLe!,
  );
  const numero = (
    (await (await client.requete("GET", "/comptes/moi", undefined, beneficiaire)).json()) as { numero: string }
  ).numero;
  const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS);
  /** Passage du planificateur n heures après la déclaration, puis file des SMS vidée. */
  const passer = async (heures: number) => {
    await app.get(PlanificateurService).examinerEcheances(new Date(declareeLe + heures * HEURE_MS));
    await app.get(FileSms).vider();
  };
  const relances = () => sms.messages.filter((m) => m.numero === numero && /déclare vous avoir payé/.test(m.texte));
  return { cotisation, beneficiaire, payeur, passer, relances };
}

describe("relance du bénéficiaire quand un paiement déclaré attend sa confirmation", () => {
  it("rien avant 24 h, un SMS à 24 h, un second à 48 h, jamais de doublon", async () => {
    const { passer, relances } = await paiementDeclare();
    await passer(23);
    expect(relances()).toHaveLength(0);
    await passer(25);
    expect(relances()).toHaveLength(1);
    expect(relances()[0]!.texte).toContain("10 000 FCFA");
    // Rejouable : un second passage dans la même tranche n'envoie rien.
    await passer(30);
    expect(relances()).toHaveLength(1);
    await passer(49);
    expect(relances()).toHaveLength(2);
    await passer(60);
    expect(relances()).toHaveLength(2);
  });

  it("serveur arrêté pendant deux jours : un seul SMS, celui de 48 h", async () => {
    const { passer, relances } = await paiementDeclare();
    await passer(50);
    expect(relances()).toHaveLength(1);
    expect(relances()[0]!.texte).toMatch(/second rappel/i);
    await passer(51);
    expect(relances()).toHaveLength(1);
  });

  it("rien si le bénéficiaire a confirmé", async () => {
    const { cotisation, beneficiaire, passer, relances } = await paiementDeclare();
    await client.requete("POST", `/cotisations/${cotisation.id}/confirmation`, undefined, beneficiaire);
    await passer(49);
    expect(relances()).toHaveLength(0);
  });

  it("rien si un litige est ouvert", async () => {
    const { cotisation, beneficiaire, passer, relances } = await paiementDeclare();
    const r = await client.requete(
      "POST",
      "/litiges",
      { cotisationId: cotisation.id, motif: "Rien reçu" },
      beneficiaire,
    );
    expect(r.status).toBe(201);
    await passer(49);
    expect(relances()).toHaveLength(0);
  });

  it("ne nomme pas le payeur et ne contient pas la référence de la transaction", async () => {
    const { passer, relances } = await paiementDeclare();
    await passer(25);
    expect(relances()[0]!.texte).not.toContain("OM-77");
    expect(relances()[0]!.texte).not.toMatch(/Membre \d/);
  });
});
