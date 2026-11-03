import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageEngagement, messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import type { DossierDePreuve } from "./modules/preuve/preuve.service.js";
import { creerClient, type Identite } from "./testing/client.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

interface ActionJournal {
  id: string;
  type: string;
  membreId: string;
  issue: string;
}

const reglementDe = (extra: Partial<Reglement> = {}): Reglement => ({
  montant: 10000,
  frequence: "hebdomadaire",
  nombreMembres: 3,
  penaliteRetard: 500,
  delaiGraceJours: 2,
  ouvert: false,
  ...extra,
});

async function cercleComplet(r: Reglement = reglementDe()) {
  const [org, a, b] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
  const cercle = (await (
    await client.requete(
      "POST",
      "/cercles",
      { reglement: r, signature: await org.signer(messageReglement(org.id, r)) },
      org,
    )
  ).json()) as Cercle;
  for (const m of [a, b]) {
    await client.requete(
      "POST",
      `/cercles/${cercle.id}/adhesions`,
      { signature: await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id)) },
      m,
    );
  }
  return { org, a, b, cercle };
}

const journal = async (cercleId: string, org: Identite) =>
  (await (
    await client.requete("GET", `/assistant/cercles/${cercleId}/journal`, undefined, org)
  ).json()) as ActionJournal[];

const envoiMiseEnDemeure = async (cercleId: string, debiteur: Identite, lese: Identite) => {
  const d = (await (
    await client.requete("GET", `/preuve/cercles/${cercleId}/membres/${debiteur.id}/dossier`, undefined, lese)
  ).json()) as DossierDePreuve;
  return d.misesEnDemeure[0]!.envoi;
};

describe("mode de l'assistant", () => {
  it("seul l'organisateur choisit le mode, parmi autonome et manuel", async () => {
    const { org, a, cercle } = await cercleComplet();
    const changer = (qui: Identite, mode: string) =>
      client.requete("POST", `/assistant/cercles/${cercle.id}/mode`, { mode }, qui);
    expect((await changer(a, "autonome")).status).toBe(403);
    expect((await changer(org, "magique")).status).toBe(400);
    expect((await changer(org, "autonome")).status).toBe(201);
  });
});

describe("assistant branché sur les événements", () => {
  it("mode manuel par défaut : un défaut donne une proposition, rien ne part sans accord", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    await app.get(PlanificateurService).constaterDefaut(cercle.id, b.id, 1);
    const [proposition] = await journal(cercle.id, org);
    expect(proposition).toMatchObject({ type: "mise_en_demeure", membreId: b.id, issue: "en_attente" });
    expect(await envoiMiseEnDemeure(cercle.id, b, a)).toBe("a_envoyer");

    expect(
      (await client.requete("POST", `/assistant/propositions/${proposition!.id}/acceptation`, undefined, a)).status,
    ).toBe(403);
    expect(
      (await client.requete("POST", `/assistant/propositions/${proposition!.id}/acceptation`, undefined, org)).status,
    ).toBe(201);
    expect(await envoiMiseEnDemeure(cercle.id, b, a)).toBe("envoyee");
    expect(
      (await client.requete("POST", `/assistant/propositions/${proposition!.id}/refus`, undefined, org)).status,
    ).toBe(400);
  });

  it("refuser une proposition : la mise en demeure ne part pas", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    await app.get(PlanificateurService).constaterDefaut(cercle.id, b.id, 1);
    const [proposition] = await journal(cercle.id, org);
    await client.requete("POST", `/assistant/propositions/${proposition!.id}/refus`, undefined, org);
    expect(await envoiMiseEnDemeure(cercle.id, b, a)).toBe("a_envoyer");
    expect((await journal(cercle.id, org))[0]!.issue).toBe("refusee");
  });

  it("mode autonome : la mise en demeure part tout de suite", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    await client.requete("POST", `/assistant/cercles/${cercle.id}/mode`, { mode: "autonome" }, org);
    await app.get(PlanificateurService).constaterDefaut(cercle.id, b.id, 1);
    expect((await journal(cercle.id, org))[0]).toMatchObject({ type: "mise_en_demeure", issue: "executee" });
    expect(await envoiMiseEnDemeure(cercle.id, b, a)).toBe("envoyee");
  });

  it("le journal n'est visible que de l'organisateur", async () => {
    const { a, cercle } = await cercleComplet();
    expect((await client.requete("GET", `/assistant/cercles/${cercle.id}/journal`, undefined, a)).status).toBe(403);
  });
});

describe("échéances examinées par le planificateur", () => {
  const JOUR = 24 * 60 * 60 * 1000;

  async function cotisation(cercleId: string, payeur: Identite, beneficiaire: Identite, dateLimite: Date) {
    const r = await client.requete(
      "POST",
      "/cotisations",
      { cercleId, beneficiaireId: beneficiaire.id, montant: 10000, dateLimite: dateLimite.toISOString() },
      payeur,
    );
    return (await r.json()) as { id: string };
  }

  it("rappels prévus par le règlement, une seule fois même si l'examen est rejoué", async () => {
    const { org, a, b, cercle } = await cercleComplet(reglementDe({ rappelsAvantEcheanceJours: [1] }));
    const maintenant = new Date("2026-11-03T08:00:00Z");
    await cotisation(cercle.id, b, a, new Date(maintenant.getTime() + JOUR));
    const planificateur = app.get(PlanificateurService);
    await planificateur.examinerEcheances(maintenant);
    await planificateur.examinerEcheances(maintenant);
    const actions = await journal(cercle.id, org);
    expect(actions).toHaveLength(1);
    expect(actions[0]).toMatchObject({ type: "rappel", membreId: b.id, issue: "en_attente" });
  });

  it("sans jours de rappel dans le règlement, aucun rappel avant l'échéance", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const maintenant = new Date("2026-11-03T08:00:00Z");
    await cotisation(cercle.id, b, a, new Date(maintenant.getTime() + JOUR));
    await app.get(PlanificateurService).examinerEcheances(maintenant);
    expect(await journal(cercle.id, org)).toHaveLength(0);
  });

  it("retard dans le délai de grâce : rappel de retard ; au-delà : rien (le défaut prend le relais)", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const maintenant = new Date("2026-11-03T08:00:00Z");
    await cotisation(cercle.id, b, a, new Date(maintenant.getTime() - JOUR));
    await cotisation(cercle.id, a, b, new Date(maintenant.getTime() - 5 * JOUR));
    await app.get(PlanificateurService).examinerEcheances(maintenant);
    const actions = await journal(cercle.id, org);
    expect(actions.map((x) => [x.type, x.membreId])).toEqual([["rappel_retard", b.id]]);
  });

  it("une cotisation d'un cercle inconnu n'arrête pas l'examen des autres", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const maintenant = new Date("2026-11-03T08:00:00Z");
    await cotisation("cercle-inconnu", a, b, new Date(maintenant.getTime() - JOUR));
    await cotisation(cercle.id, b, a, new Date(maintenant.getTime() - JOUR));
    const bilan = await app.get(PlanificateurService).examinerEcheances(maintenant);
    expect(bilan.echecs).toBeGreaterThanOrEqual(1);
    expect(await journal(cercle.id, org)).toHaveLength(1);
  });
});
