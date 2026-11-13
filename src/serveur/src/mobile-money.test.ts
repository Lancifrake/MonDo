import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { RegistreService, type RegistreDuCercle } from "./registre/registre.service.js";
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
afterEach(() => vi.unstubAllEnvs());

const json = async <T>(r: Response) => (await r.json()) as T;
const HEURE_MS = 60 * 60 * 1000;

interface PaiementSimule {
  id: string;
  operateur: string;
  issue: string;
  statut: "en_attente_operateur" | "reussi" | "echoue";
  referenceOperateur?: string;
  motif?: string;
}

async function premierTour() {
  const { membres, cercle } = await cercleComplet(client);
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const [payeur, autre] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
  const due = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1 && c.payeurId === payeur.id)!;
  const payer = (issue: string, qui: Identite = payeur, operateur = "orange_money") =>
    client.requete("POST", `/cotisations/${due.id}/paiement-simule`, { operateur, issue }, qui);
  const etat = async () => (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.id === due.id)!;
  return { cercle, beneficiaire, payeur, autre, due, payer, etat };
}

describe("Mobile Money simulé (cahier des charges, M4) : trois issues", () => {
  it("réussi : l'opérateur simulé répond, le paiement est déclaré avec sa référence ; le bénéficiaire confirme lui-même", async () => {
    const { beneficiaire, due, payer, etat } = await premierTour();
    const r = await payer("reussi");
    expect(r.status).toBe(201);
    const p = await json<PaiementSimule>(r);
    expect(p).toMatchObject({ statut: "reussi", operateur: "orange_money" });
    expect(p.referenceOperateur).toMatch(/^OM-SIM-/);
    expect(await etat()).toMatchObject({ statut: "declaree", referenceTransaction: p.referenceOperateur });
    // Le retour de l'opérateur ne remplace pas la confirmation : MonDo ne voit pas l'argent arriver.
    await app.get(FileSms).vider();
    const numero = (
      await json<{ numero: string }>(await client.requete("GET", "/comptes/moi", undefined, beneficiaire))
    ).numero;
    const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages.filter((m) => m.numero === numero);
    expect(sms.at(-1)!.texte).toMatch(/confirm/i);
    expect((await client.requete("POST", `/cotisations/${due.id}/confirmation`, undefined, beneficiaire)).status).toBe(
      201,
    );
  });

  it("échoué : rien n'est déclaré, la cotisation reste à payer, le payeur sait pourquoi et peut réessayer", async () => {
    const { payeur, payer, etat, due } = await premierTour();
    const p = await json<PaiementSimule>(await payer("echoue", payeur, "mtn_momo"));
    expect(p).toMatchObject({ statut: "echoue", operateur: "mtn_momo" });
    expect(p.motif).toMatch(/solde/i);
    expect((await etat()).statut).toBe("due");
    const tentatives = await json<PaiementSimule[]>(
      await client.requete("GET", `/cotisations/${due.id}/paiements-simules`, undefined, payeur),
    );
    expect(tentatives.map((t) => t.statut)).toEqual(["echoue"]);
    expect((await json<PaiementSimule>(await payer("reussi"))).statut).toBe("reussi");
  });

  it("en retard : l'opérateur répond plus tard ; le planificateur traite son retour au passage suivant", async () => {
    const { payer, etat } = await premierTour();
    const p = await json<PaiementSimule>(await payer("en_retard"));
    expect(p.statut).toBe("en_attente_operateur");
    expect((await etat()).statut).toBe("due");
    // Une seule tentative en attente à la fois.
    expect((await payer("reussi")).status).toBe(409);
    const planificateur = app.get(PlanificateurService);
    await planificateur.examinerEcheances(new Date(Date.now() + 10 * 60 * 1000));
    expect((await etat()).statut).toBe("due");
    await planificateur.examinerEcheances(new Date(Date.now() + HEURE_MS + 60 * 1000));
    expect((await etat()).statut).toBe("declaree");
    await planificateur.examinerEcheances(new Date(Date.now() + 2 * HEURE_MS));
    expect((await etat()).statut).toBe("declaree");
  });

  it("réservé au payeur, sur une cotisation à payer ; corps strict ; refusé en production", async () => {
    const { beneficiaire, autre, payer, due } = await premierTour();
    expect((await payer("reussi", beneficiaire)).status).toBe(403);
    expect((await payer("reussi", autre)).status).toBe(403);
    expect(
      (
        await client.requete("POST", `/cotisations/${due.id}/paiement-simule`, {
          operateur: "orange_money",
          issue: "reussi",
        })
      ).status,
    ).toBe(401);
    expect((await payer("peut_etre")).status).toBe(400);
    expect((await payer("reussi", undefined, "wave")).status).toBe(400);
    expect((await client.requete("GET", `/cotisations/${due.id}/paiements-simules`, undefined, autre)).status).toBe(
      403,
    );
    vi.stubEnv("NODE_ENV", "production");
    const r = await payer("reussi");
    expect(r.status).toBe(403);
    expect((await json<{ message: string }>(r)).message).toMatch(/production/);
    vi.unstubAllEnvs();
    expect((await payer("reussi")).status).toBe(201);
    expect((await payer("reussi")).status).toBe(400);
  });
});

describe("chaque confirmation et chaque défaut laissent une trace au registre (M4, M10)", () => {
  it("cotisation confirmée et défaut constaté figurent dans le registre du cercle", async () => {
    const { cercle, beneficiaire, payeur, autre, due, payer } = await premierTour();
    await payer("reussi");
    await client.requete("POST", `/cotisations/${due.id}/confirmation`, undefined, beneficiaire);
    const dueAutre = (await cotisationsDe(client, cercle.id, autre)).find(
      (c) => c.tour === 1 && c.payeurId === autre.id,
    )!;
    await app.get(PlanificateurService).examinerEcheances(new Date(Date.parse(dueAutre.finGrace) + HEURE_MS));
    await app.get(RegistreService).fermerLot();
    const reg = await json<RegistreDuCercle>(
      await client.requete("GET", `/cercles/${cercle.id}/registre`, undefined, payeur),
    );
    const objets = reg.evenements.map((e) => e.objet);
    expect(objets).toContain("cotisation_confirmee");
    expect(objets).toContain("defaut_constate");
    expect(reg.integre).toBe(true);
  });
});
