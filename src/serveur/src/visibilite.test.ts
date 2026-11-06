import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, cercleComplet, creerCercle, reglementDeTest } from "./testing/cercles.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const voirCercle = async (id: string, qui: Identite) =>
  (await (await client.requete("GET", `/cercles/${id}`, undefined, qui)).json()) as Record<string, unknown>;
const voirScore = (de: Identite, qui: Identite) => client.requete("GET", `/score/${de.id}`, undefined, qui);

describe("visibilité d'un cercle (choix de David, 06/11)", () => {
  it("avec le lien, un non-membre voit le règlement et les places restantes, jamais les membres ni l'ordre", async () => {
    const org = await client.inscrire();
    const cree = (await (await creerCercle(client, org, reglementDeTest({ nombreMembres: 4 }))).json()) as Cercle;
    await adherer(client, cree, await client.inscrire());
    const curieux = await client.inscrire();
    const vu = await voirCercle(cree.id, curieux);
    expect(vu).toMatchObject({
      id: cree.id,
      statut: "en_attente",
      reglement: cree.reglement,
      empreinteReglement: cree.empreinteReglement,
      placesRestantes: 2,
    });
    expect(vu).not.toHaveProperty("membres");
    expect(vu).not.toHaveProperty("ordre");
  });

  it("un membre voit la liste des membres et l'ordre de passage", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const vu = await voirCercle(cercle.id, membres[2]!);
    expect(vu.membres).toEqual(membres.map((m) => m.id));
    expect(vu.ordre).toHaveLength(3);
    expect(vu.placesRestantes).toBe(0);
  });

  it("cercle complet vu par un non-membre : statut sans membres ni ordre", async () => {
    const { cercle } = await cercleComplet(client);
    const vu = await voirCercle(cercle.id, await client.inscrire());
    expect(vu).toMatchObject({ statut: "complet", placesRestantes: 0 });
    expect(vu).not.toHaveProperty("ordre");
  });
});

describe("visibilité du score (choix de David, 06/11)", () => {
  it("chacun voit son propre score", async () => {
    const moi = await client.inscrire();
    expect((await voirScore(moi, moi)).status).toBe(200);
  });

  it("les membres d'un même cercle voient le score les uns des autres, dès l'adhésion", async () => {
    const org = await client.inscrire();
    const cree = (await (await creerCercle(client, org, reglementDeTest({ nombreMembres: 4 }))).json()) as Cercle;
    const nouveau = await client.inscrire();
    await adherer(client, cree, nouveau);
    expect((await voirScore(org, nouveau)).status).toBe(200);
    expect((await voirScore(nouveau, org)).status).toBe(200);
  });

  it("sans cercle commun : refusé", async () => {
    const [a, b] = [await client.inscrire(), await client.inscrire()];
    expect((await voirScore(a, b)).status).toBe(403);
    const { membres } = await cercleComplet(client);
    expect((await voirScore(membres[0]!, a)).status).toBe(403);
  });
});
