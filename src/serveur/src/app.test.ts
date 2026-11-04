import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { AppModule } from "./app.module.js";
import { messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { cercleComplet, cotisationsDe, dansJours } from "./testing/cercles.js";
import { creerClient, type Identite } from "./testing/client.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

/** Une cotisation du premier tour, avec son payeur et son bénéficiaire, dans un vrai cercle complet. */
async function cotisationDuPremierTour() {
  const { membres, cercle } = await cercleComplet(client);
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const payeur = membres.find((m) => m.id !== beneficiaire.id)!;
  const { id } = (await cotisationsDe(client, cercle.id, payeur)).find(
    (c) => c.payeurId === payeur.id && c.tour === 1,
  )!;
  return { payeur, beneficiaire, id };
}

async function cotisationDeclaree() {
  const c = await cotisationDuPremierTour();
  await client.requete("POST", `/cotisations/${c.id}/paiement`, { referenceTransaction: "OM123" }, c.payeur);
  return c;
}

const score = async (qui: Identite) =>
  (await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as {
    score: number;
    defauts: number;
  };

describe("Cotisations -> Score, par événements seulement", () => {
  it("une cotisation confirmée à temps donne +4 au payeur", async () => {
    const { payeur, beneficiaire, id } = await cotisationDeclaree();
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, beneficiaire)).status).toBe(201);
    expect((await score(payeur)).score).toBe(4);
  });

  it("le payeur ne peut pas confirmer à la place du bénéficiaire", async () => {
    const { payeur, id } = await cotisationDeclaree();
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, payeur)).status).toBe(403);
  });

  it("seul le payeur déclare son paiement", async () => {
    const { id } = await cotisationDuPremierTour();
    const intrus = await client.inscrire();
    expect(
      (await client.requete("POST", `/cotisations/${id}/paiement`, { referenceTransaction: "X" }, intrus)).status,
    ).toBe(403);
  });

  it("sans paiement déclaré, la confirmation est refusée (le silence ne vaut pas confirmation)", async () => {
    const { beneficiaire, id } = await cotisationDuPremierTour();
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, beneficiaire)).status).toBe(400);
  });

  it("un défaut constaté fait baisser le score, une seule fois même si le planificateur est rejoué", async () => {
    const luc = await client.inscrire();
    const r: Reglement = {
      montant: 1000,
      frequence: "mensuelle",
      nombreMembres: 3,
      penaliteRetard: 0,
      delaiGraceJours: 2,
      ouvert: false,
      datePremierTour: dansJours(7),
    };
    const cercle = (await (
      await client.requete(
        "POST",
        "/cercles",
        { reglement: r, signature: await luc.signer(messageReglement(luc.id, r)) },
        luc,
      )
    ).json()) as Cercle;
    const planificateur = app.get(PlanificateurService);
    expect(await planificateur.constaterDefaut(cercle.id, luc.id, 1)).toBe(true);
    expect(await planificateur.constaterDefaut(cercle.id, luc.id, 1)).toBe(false);
    expect(await score(luc)).toMatchObject({ score: 0, defauts: 1 });
  });
});

describe("fiabilité du planificateur", () => {
  it("un constat qui échoue redevient rejouable", async () => {
    const planificateur = app.get(PlanificateurService);
    const inconnu = "00000000-0000-0000-0000-000000000000";
    await expect(planificateur.constaterDefaut(inconnu, inconnu, 1)).rejects.toThrow();
    await expect(planificateur.constaterDefaut(inconnu, inconnu, 1)).rejects.toThrow();
  });
});

describe("Règle de propriété des données (décision 02)", () => {
  it("le module Cotisations n'importe jamais le module Score", () => {
    const dossier = join(import.meta.dirname, "modules", "cotisations");
    for (const f of readdirSync(dossier)) {
      expect(readFileSync(join(dossier, f), "utf-8")).not.toMatch(/modules\/score|\.\.\/score\//);
    }
  });
});
