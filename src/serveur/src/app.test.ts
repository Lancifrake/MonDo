import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { AppModule } from "./app.module.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";

let app: INestApplication;
let base: string;

beforeAll(async () => {
  const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
  app = module.createNestApplication();
  await app.listen(0);
  base = await app.getUrl();
});
afterAll(async () => app.close());

const post = (url: string, corps: unknown) =>
  fetch(base + url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(corps) });

async function cotisation(dateLimite: string) {
  const r = await post("/cotisations", { cercleId: "c1", payeurId: "paul", beneficiaireId: "awa", montant: 10000, dateLimite });
  return (await r.json()) as { id: string };
}

describe("Cotisations -> Score, par événements seulement", () => {
  it("une cotisation confirmée à temps donne +4 au payeur", async () => {
    const c = await cotisation("2999-01-01T00:00:00Z");
    await post(`/cotisations/${c.id}/paiement`, { referenceTransaction: "OM123" });
    const r = await post(`/cotisations/${c.id}/confirmation`, { membreId: "awa" });
    expect(r.status).toBe(201);
    const score = (await (await fetch(`${base}/score/paul`)).json()) as { score: number };
    expect(score.score).toBe(4);
  });

  it("le payeur ne peut pas se confirmer lui-même", async () => {
    const c = await cotisation("2999-01-01T00:00:00Z");
    await post(`/cotisations/${c.id}/paiement`, { referenceTransaction: "OM124" });
    const r = await post(`/cotisations/${c.id}/confirmation`, { membreId: "paul" });
    expect(r.status).toBe(400);
  });

  it("sans paiement déclaré, la confirmation est refusée (le silence ne vaut pas confirmation)", async () => {
    const c = await cotisation("2999-01-01T00:00:00Z");
    const r = await post(`/cotisations/${c.id}/confirmation`, { membreId: "awa" });
    expect(r.status).toBe(400);
  });

  it("un défaut constaté fait baisser le score, une seule fois même si le planificateur est rejoué", async () => {
    const planificateur = app.get(PlanificateurService);
    expect(planificateur.constaterDefaut("c2", "luc", 1)).toBe(true);
    expect(planificateur.constaterDefaut("c2", "luc", 1)).toBe(false);
    const score = (await (await fetch(`${base}/score/luc`)).json()) as { score: number; defauts: number };
    expect(score).toMatchObject({ score: 0, defauts: 1 });
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
