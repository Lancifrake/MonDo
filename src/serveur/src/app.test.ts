import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { AppModule } from "./app.module.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { creerClient, type Identite } from "./testing/client.js";

let app: INestApplication;
let client: ReturnType<typeof creerClient>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = creerClient(await app.getUrl());
});
afterAll(async () => app.close());

async function cotisationDeclaree(payeur: Identite, beneficiaire: Identite) {
  const r = await client.requete(
    "POST",
    "/cotisations",
    { cercleId: "c1", beneficiaireId: beneficiaire.id, montant: 10000, dateLimite: "2999-01-01T00:00:00Z" },
    payeur,
  );
  const { id } = (await r.json()) as { id: string };
  await client.requete("POST", `/cotisations/${id}/paiement`, { referenceTransaction: "OM123" }, payeur);
  return id;
}

const score = async (qui: Identite) =>
  (await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as {
    score: number;
    defauts: number;
  };

describe("Cotisations -> Score, par événements seulement", () => {
  it("une cotisation confirmée à temps donne +4 au payeur", async () => {
    const [paul, awa] = [await client.inscrire(), await client.inscrire()];
    const id = await cotisationDeclaree(paul, awa);
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, awa)).status).toBe(201);
    expect((await score(paul)).score).toBe(4);
  });

  it("le payeur ne peut pas confirmer à la place du bénéficiaire", async () => {
    const [paul, awa] = [await client.inscrire(), await client.inscrire()];
    const id = await cotisationDeclaree(paul, awa);
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, paul)).status).toBe(403);
  });

  it("seul le payeur déclare son paiement", async () => {
    const [paul, awa, intrus] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    const r = await client.requete(
      "POST",
      "/cotisations",
      { cercleId: "c1", beneficiaireId: awa.id, montant: 10000, dateLimite: "2999-01-01T00:00:00Z" },
      paul,
    );
    const { id } = (await r.json()) as { id: string };
    expect(
      (await client.requete("POST", `/cotisations/${id}/paiement`, { referenceTransaction: "X" }, intrus)).status,
    ).toBe(403);
  });

  it("sans paiement déclaré, la confirmation est refusée (le silence ne vaut pas confirmation)", async () => {
    const [paul, awa] = [await client.inscrire(), await client.inscrire()];
    const r = await client.requete(
      "POST",
      "/cotisations",
      { cercleId: "c1", beneficiaireId: awa.id, montant: 10000, dateLimite: "2999-01-01T00:00:00Z" },
      paul,
    );
    const { id } = (await r.json()) as { id: string };
    expect((await client.requete("POST", `/cotisations/${id}/confirmation`, undefined, awa)).status).toBe(400);
  });

  it("un défaut constaté fait baisser le score, une seule fois même si le planificateur est rejoué", async () => {
    const luc = await client.inscrire();
    const planificateur = app.get(PlanificateurService);
    expect(planificateur.constaterDefaut("c2", luc.id, 1)).toBe(true);
    expect(planificateur.constaterDefaut("c2", luc.id, 1)).toBe(false);
    expect(await score(luc)).toMatchObject({ score: 0, defauts: 1 });
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
