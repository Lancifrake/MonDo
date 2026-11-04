import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageEngagement, messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { dansJours } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const reglement = (extra: Partial<Reglement> = {}): Reglement => ({
  montant: 10000,
  frequence: "hebdomadaire",
  nombreMembres: 3,
  penaliteRetard: 500,
  delaiGraceJours: 2,
  ouvert: false,
  datePremierTour: dansJours(7),
  ...extra,
});

async function creerCercle(org: Identite, r: Reglement) {
  return client.requete(
    "POST",
    "/cercles",
    { reglement: r, signature: await org.signer(messageReglement(org.id, r)) },
    org,
  );
}

async function adherer(cercle: Cercle, m: Identite) {
  const signature = await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id));
  return client.requete("POST", `/cercles/${cercle.id}/adhesions`, { signature }, m);
}

describe("Cercles : règlement et engagements signés", () => {
  it("crée un cercle quand le règlement est signé par l'organisateur", async () => {
    const r = await creerCercle(await client.inscrire(), reglement());
    expect(r.status).toBe(201);
    expect(((await r.json()) as Cercle).statut).toBe("en_attente");
  });

  it("refuse un règlement signé par un autre téléphone ou modifié après signature", async () => {
    const [org, autre] = [await client.inscrire(), await client.inscrire()];
    const r = reglement();
    const mauvaise = await client.requete(
      "POST",
      "/cercles",
      { reglement: r, signature: await autre.signer(messageReglement(org.id, r)) },
      org,
    );
    expect(mauvaise.status).toBe(403);
    const modifie = await client.requete(
      "POST",
      "/cercles",
      { reglement: { ...r, penaliteRetard: 0 }, signature: await org.signer(messageReglement(org.id, r)) },
      org,
    );
    expect(modifie.status).toBe(403);
  });

  it("un cercle ouvert à des inconnus exige le niveau 2", async () => {
    const org = await client.inscrire();
    await org.niveau2();
    const cercle = (await (await creerCercle(org, reglement({ ouvert: true }))).json()) as Cercle;
    expect((await adherer(cercle, await client.inscrire())).status).toBe(403);
    const verifie = await client.inscrire();
    await verifie.niveau2();
    expect((await adherer(cercle, verifie)).status).toBe(201);
  });

  it("refuse une adhésion dont l'engagement n'est pas signé par le membre", async () => {
    const cercle = (await (await creerCercle(await client.inscrire(), reglement())).json()) as Cercle;
    const [m, usurpateur] = [await client.inscrire(), await client.inscrire()];
    const signature = await usurpateur.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id));
    expect((await client.requete("POST", `/cercles/${cercle.id}/adhesions`, { signature }, m)).status).toBe(403);
  });

  it("quand le cercle est complet, l'ordre est figé selon le score", async () => {
    const org = await client.inscrire();
    const cercle = (await (await creerCercle(org, reglement())).json()) as Cercle;
    const [a, b] = [await client.inscrire(), await client.inscrire()];
    await adherer(cercle, a);
    const complet = (await (await adherer(cercle, b)).json()) as Cercle;
    expect(complet.statut).toBe("complet");
    // tous à 0 : ordre d'inscription
    expect(complet.ordre!.map((p) => p.membreId)).toEqual([org.id, a.id, b.id]);
    expect((await adherer(cercle, await client.inscrire())).status).toBe(400);
  });
});
