import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { ComptesService } from "./modules/comptes/comptes.service.js";
import { creerClient } from "./testing/client.js";
import { creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());
afterEach(() => vi.unstubAllEnvs());

describe("vérification d'identité (niveau 2) simulée", () => {
  it("hors production : le membre passe au niveau 2 (simulation du prototype)", async () => {
    const m = await client.inscrire();
    const r = await m.niveau2();
    expect(r.status).toBe(201);
    expect(await r.json()).toMatchObject({ niveau: 2 });
  });

  it("en production : refusée, le niveau 2 passe par le dépôt des pièces et un administrateur", async () => {
    const m = await client.inscrire();
    vi.stubEnv("NODE_ENV", "production");
    const r = await m.niveau2();
    expect(r.status).toBe(403);
    expect(((await r.json()) as { message: string }).message).toMatch(/administrateur/);
    expect((await app.get(ComptesService).trouver(m.id)).niveau).toBe(1);
  });

  it("organiser un cercle ouvert exige le niveau 2 ; un cercle privé reste libre", async () => {
    const org = await client.inscrire();
    const ouvert = reglementDeTest({ ouvert: true });
    const refus = await creerCercle(client, org, ouvert);
    expect(refus.status).toBe(403);
    expect(((await refus.json()) as { message: string }).message).toMatch(/niveau 2/);
    expect((await creerCercle(client, org, reglementDeTest())).status).toBe(201);
    await org.niveau2();
    expect((await creerCercle(client, org, ouvert)).status).toBe(201);
  });
});
