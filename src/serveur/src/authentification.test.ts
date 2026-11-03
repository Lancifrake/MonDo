import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageInscription } from "./authentification/messages.js";
import { creerClient } from "./testing/client.js";
import { nouveauTelephone } from "./testing/telephone.js";

let app: INestApplication;
let client: ReturnType<typeof creerClient>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = creerClient(await app.getUrl());
});
afterAll(async () => app.close());

describe("authentification par requêtes signées", () => {
  it("refuse une requête sans signature", async () => {
    const moi = await client.inscrire();
    expect((await client.requete("GET", `/score/${moi.id}`)).status).toBe(401);
  });

  it("accepte une requête signée par le bon téléphone", async () => {
    const moi = await client.inscrire();
    expect((await client.requete("GET", `/score/${moi.id}`, undefined, moi)).status).toBe(200);
  });

  it("refuse quelqu'un qui se fait passer pour un autre membre", async () => {
    const [victime, pirate] = [await client.inscrire(), await client.inscrire()];
    const usurpation = { id: victime.id, signer: pirate.signer };
    expect((await client.requete("GET", `/score/${victime.id}`, undefined, usurpation)).status).toBe(401);
  });

  it("refuse une requête trop ancienne", async () => {
    const moi = await client.inscrire();
    const ancien = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    expect((await client.requete("GET", `/score/${moi.id}`, undefined, moi, { horodatage: ancien })).status).toBe(401);
  });

  it("refuse le rejeu exact d'une requête déjà vue", async () => {
    const moi = await client.inscrire();
    const horodatage = new Date().toISOString();
    const { messageRequete } = await import("./authentification/messages.js");
    const signature = await moi.signer(messageRequete("GET", `/score/${moi.id}`, horodatage, undefined));
    expect((await client.requete("GET", `/score/${moi.id}`, undefined, moi, { horodatage, signature })).status).toBe(
      200,
    );
    expect((await client.requete("GET", `/score/${moi.id}`, undefined, moi, { horodatage, signature })).status).toBe(
      401,
    );
  });

  it("refuse un corps modifié après signature", async () => {
    const moi = await client.inscrire();
    const horodatage = new Date().toISOString();
    const { messageRequete } = await import("./authentification/messages.js");
    const signature = await moi.signer(messageRequete("POST", `/comptes/${moi.id}/niveau2`, horodatage, { a: 1 }));
    const r = await client.requete("POST", `/comptes/${moi.id}/niveau2`, { a: 2 }, moi, { horodatage, signature });
    expect(r.status).toBe(401);
  });

  it("un membre ne peut pas faire passer un autre au niveau 2", async () => {
    const [a, b] = [await client.inscrire(), await client.inscrire()];
    expect((await client.requete("POST", `/comptes/${b.id}/niveau2`, undefined, a)).status).toBe(403);
  });
});

describe("inscription", () => {
  it("exige la preuve de détention de la clé privée", async () => {
    const [tel, autre] = [await nouveauTelephone(), await nouveauTelephone()];
    const donnees = { numero: "+237690000001", nom: "Awa", clePublique: tel.clePublique };
    const sansPreuve = await client.requete("POST", "/comptes", donnees);
    expect(sansPreuve.status).toBe(400);
    const mauvaisePreuve = await client.requete("POST", "/comptes", {
      ...donnees,
      preuve: await autre.signer(messageInscription(donnees)),
    });
    expect(mauvaisePreuve.status).toBe(403);
  });
});

describe("validation des entrées", () => {
  it.each([
    ["numéro invalide", { numero: "abc" }],
    ["nom vide", { nom: "" }],
    ["champ inconnu", { admin: true }],
  ])("refuse une inscription avec %s", async (_, modif) => {
    const tel = await nouveauTelephone();
    const donnees = { numero: "+237690000002", nom: "Paul", clePublique: tel.clePublique, ...modif };
    const r = await client.requete("POST", "/comptes", { ...donnees, preuve: "x" });
    expect(r.status).toBe(400);
  });

  it.each([
    ["montant négatif", { montant: -1 }],
    ["nombre de membres non entier", { nombreMembres: 3.5 }],
    ["moins de 3 membres", { nombreMembres: 2 }],
    ["fréquence inconnue", { frequence: "annuelle" }],
    ["délai de grâce négatif", { delaiGraceJours: -1 }],
  ])("refuse un règlement avec %s", async (_, modif) => {
    const org = await client.inscrire();
    const reglement = {
      montant: 10000,
      frequence: "hebdomadaire",
      nombreMembres: 3,
      penaliteRetard: 500,
      delaiGraceJours: 2,
      ouvert: false,
      ...modif,
    };
    const r = await client.requete("POST", "/cercles", { reglement, signature: "x" }, org);
    expect(r.status).toBe(400);
  });
});
