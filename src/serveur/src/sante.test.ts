import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";

let app: INestApplication;
let url: string;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  url = await app.getUrl();
});
afterAll(async () => app.close());

describe("santé du serveur", () => {
  it("sans signature : répond que le serveur et la base sont joignables", async () => {
    const r = await fetch(`${url}/sante`);
    expect(r.status).toBe(200);
    expect(await r.json()).toEqual({ statut: "ok" });
  });

  it("base injoignable : 503, sans détail technique", async () => {
    const base = app.get<BaseDeDonnees>(BASE_DE_DONNEES);
    const espion = vi.spyOn(base, "requete").mockRejectedValueOnce(new Error("connexion refusée à 10.0.0.3"));
    const r = await fetch(`${url}/sante`);
    espion.mockRestore();
    expect(r.status).toBe(503);
    expect(JSON.stringify(await r.json())).not.toContain("10.0.0.3");
  });
});
