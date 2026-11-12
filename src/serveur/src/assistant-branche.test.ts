import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageEngagement, messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import type { DossierDePreuve } from "./modules/preuve/preuve.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { avecBareme, cotisationsDe, dansJours } from "./testing/cercles.js";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";

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

const reglementDe = (extra: Partial<Reglement> = {}): Reglement =>
  avecBareme({
    montant: 10000,
    frequence: "hebdomadaire",
    nombreMembres: 3,
    penaliteRetard: 500,
    delaiGraceJours: 2,
    ouvert: false,
    datePremierTour: dansJours(7),
    ...extra,
  });

async function cercleComplet(r: Reglement = reglementDe()) {
  const [org, a, b] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
  const cercle = (await (
    await client.requete(
      "POST",
      "/cercles",
      {
        reglement: r,
        placeSouhaitee: r.nombreMembres,
        signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
      },
      org,
    )
  ).json()) as Cercle;
  for (const m of [a, b]) {
    await client.requete(
      "POST",
      `/cercles/${cercle.id}/adhesions`,
      {
        placeSouhaitee: cercle.reglement.nombreMembres,
        signature: await m.signer(
          messageEngagement(cercle.id, cercle.empreinteReglement, m.id, cercle.reglement.nombreMembres),
        ),
      },
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

  /** Date limite et payeurs du premier tour, lus dans les cotisations générées. */
  async function premierTour(cercleId: string, membres: Identite[]) {
    const toutes = (await Promise.all(membres.map((m) => cotisationsDe(client, cercleId, m)))).flat();
    const tour1 = toutes.filter((c) => c.tour === 1);
    return {
      dateLimite: Date.parse(tour1[0]!.dateLimite),
      payeurs: [...new Set(tour1.map((c) => c.payeurId))].sort(),
    };
  }

  it("rappels prévus par le règlement, une seule fois même si l'examen est rejoué", async () => {
    const { org, a, b, cercle } = await cercleComplet(reglementDe({ rappelsAvantEcheanceJours: [1] }));
    const { dateLimite, payeurs } = await premierTour(cercle.id, [org, a, b]);
    const maintenant = new Date(dateLimite - JOUR);
    const planificateur = app.get(PlanificateurService);
    await planificateur.examinerEcheances(maintenant);
    await planificateur.examinerEcheances(maintenant);
    const actions = await journal(cercle.id, org);
    // Seul le premier tour est à un jour ; les tours suivants sont à 8 et 15 jours.
    expect(actions.every((x) => x.type === "rappel" && x.issue === "en_attente")).toBe(true);
    expect(actions.map((x) => x.membreId).sort()).toEqual(payeurs);
  });

  it("sans jours de rappel dans le règlement, aucun rappel avant l'échéance", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const { dateLimite } = await premierTour(cercle.id, [org, a, b]);
    await app.get(PlanificateurService).examinerEcheances(new Date(dateLimite - JOUR));
    expect(await journal(cercle.id, org)).toHaveLength(0);
  });

  it("retard dans le délai de grâce : rappel de retard aux payeurs du tour", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const { dateLimite, payeurs } = await premierTour(cercle.id, [org, a, b]);
    await app.get(PlanificateurService).examinerEcheances(new Date(dateLimite + JOUR));
    const actions = await journal(cercle.id, org);
    expect(actions.every((x) => x.type === "rappel_retard")).toBe(true);
    expect(actions.map((x) => x.membreId).sort()).toEqual(payeurs);
  });

  it("au-delà du délai de grâce : plus de rappel (le défaut prend le relais)", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const { dateLimite } = await premierTour(cercle.id, [org, a, b]);
    await app.get(PlanificateurService).examinerEcheances(new Date(dateLimite + 5 * JOUR));
    expect((await journal(cercle.id, org)).filter((x) => x.type === "rappel_retard")).toHaveLength(0);
  });

  it("une cotisation d'un cercle inconnu n'arrête pas l'examen des autres", async () => {
    const { org, a, b, cercle } = await cercleComplet();
    const { dateLimite, payeurs } = await premierTour(cercle.id, [org, a, b]);
    const maintenant = new Date(dateLimite + JOUR);
    await app.get<BaseDeDonnees>(BASE_DE_DONNEES).requete(
      `INSERT INTO cotisations.cotisations (id, cercle_id, payeur_id, beneficiaire_id, montant, date_limite, statut)
         VALUES ($1, 'cercle-inconnu', $2, $3, 10000, $4, 'due')`,
      [randomUUID(), a.id, b.id, new Date(dateLimite).toISOString()],
    );
    const bilan = await app.get(PlanificateurService).examinerEcheances(maintenant);
    expect(bilan.echecs).toBeGreaterThanOrEqual(1);
    expect(await journal(cercle.id, org)).toHaveLength(payeurs.length);
  });
});
