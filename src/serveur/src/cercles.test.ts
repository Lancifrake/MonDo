import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageEngagement, messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { nouveauTelephone } from "./testing/telephone.js";

let app: INestApplication;
let base: string;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  base = await app.getUrl();
});
afterAll(async () => app.close());

const post = (url: string, corps?: unknown) =>
  fetch(base + url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(corps ?? {}) });

let compteur = 0;
async function inscrire(niveau2 = false) {
  const tel = await nouveauTelephone();
  const r = await post("/comptes", { numero: `+23767000${String(++compteur).padStart(4, "0")}`, nom: `Membre ${compteur}`, clePublique: tel.clePublique });
  const compte = (await r.json()) as { id: string };
  if (niveau2) await post(`/comptes/${compte.id}/niveau2`);
  return { id: compte.id, signer: tel.signer };
}

const reglement = (extra: Partial<Reglement> = {}): Reglement => ({
  montant: 10000, frequence: "hebdomadaire", nombreMembres: 3, penaliteRetard: 500, delaiGraceJours: 2, ouvert: false, ...extra,
});

async function creerCercle(org: Awaited<ReturnType<typeof inscrire>>, r: Reglement) {
  return post("/cercles", { organisateurId: org.id, reglement: r, signature: await org.signer(messageReglement(org.id, r)) });
}

async function adherer(cercle: Cercle, m: Awaited<ReturnType<typeof inscrire>>) {
  return post(`/cercles/${cercle.id}/adhesions`, { membreId: m.id, signature: await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id)) });
}

describe("Comptes", () => {
  it("refuse une clé qui contient une partie privée", async () => {
    const r = await post("/comptes", { numero: "+237670009999", nom: "X", clePublique: { kty: "EC", crv: "P-256", x: "a", y: "b", d: "secret" } });
    expect(r.status).toBe(400);
  });

  it("refuse deux comptes avec le même numéro", async () => {
    const tel = await nouveauTelephone();
    const c = { numero: "+237670008888", nom: "Doublon", clePublique: tel.clePublique };
    expect((await post("/comptes", c)).status).toBe(201);
    expect((await post("/comptes", c)).status).toBe(409);
  });
});

describe("Cercles : règlement et engagements signés", () => {
  it("crée un cercle quand le règlement est signé par l'organisateur", async () => {
    const org = await inscrire();
    const r = await creerCercle(org, reglement());
    expect(r.status).toBe(201);
    expect(((await r.json()) as Cercle).statut).toBe("en_attente");
  });

  it("refuse un règlement signé par un autre téléphone ou modifié après signature", async () => {
    const [org, autre] = [await inscrire(), await inscrire()];
    const r = reglement();
    const mauvaise = await post("/cercles", { organisateurId: org.id, reglement: r, signature: await autre.signer(messageReglement(org.id, r)) });
    expect(mauvaise.status).toBe(403);
    const modifie = await post("/cercles", { organisateurId: org.id, reglement: { ...r, penaliteRetard: 0 }, signature: await org.signer(messageReglement(org.id, r)) });
    expect(modifie.status).toBe(403);
  });

  it("un cercle ouvert à des inconnus exige le niveau 2", async () => {
    const org = await inscrire(true);
    const cercle = (await (await creerCercle(org, reglement({ ouvert: true }))).json()) as Cercle;
    const niveau1 = await inscrire(false);
    expect((await adherer(cercle, niveau1)).status).toBe(403);
    const niveau2 = await inscrire(true);
    expect((await adherer(cercle, niveau2)).status).toBe(201);
  });

  it("refuse une adhésion dont la signature n'est pas celle du membre", async () => {
    const org = await inscrire();
    const cercle = (await (await creerCercle(org, reglement())).json()) as Cercle;
    const [m, usurpateur] = [await inscrire(), await inscrire()];
    const r = await post(`/cercles/${cercle.id}/adhesions`, { membreId: m.id, signature: await usurpateur.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id)) });
    expect(r.status).toBe(403);
  });

  it("quand le cercle est complet, l'ordre est figé selon le score", async () => {
    const org = await inscrire();
    const cercle = (await (await creerCercle(org, reglement())).json()) as Cercle;
    const [a, b] = [await inscrire(), await inscrire()];
    await adherer(cercle, a);
    const r = await adherer(cercle, b);
    const complet = (await r.json()) as Cercle;
    expect(complet.statut).toBe("complet");
    expect(complet.ordre).toHaveLength(3);
    // tous à 0 : ordre d'inscription
    expect(complet.ordre!.map((p) => p.membreId)).toEqual([org.id, a.id, b.id]);
    expect((await adherer(cercle, await inscrire())).status).toBe(400);
  });
});
