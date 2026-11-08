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
    {
      reglement: r,
      placeSouhaitee: r.nombreMembres,
      signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
    },
    org,
  );
}

async function adherer(cercle: Cercle, m: Identite, placeSouhaitee = cercle.reglement.nombreMembres) {
  const signature = await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id, placeSouhaitee));
  return client.requete("POST", `/cercles/${cercle.id}/adhesions`, { placeSouhaitee, signature }, m);
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
      {
        reglement: r,
        placeSouhaitee: r.nombreMembres,
        signature: await autre.signer(messageReglement(org.id, r, r.nombreMembres)),
      },
      org,
    );
    expect(mauvaise.status).toBe(403);
    const modifie = await client.requete(
      "POST",
      "/cercles",
      {
        reglement: { ...r, penaliteRetard: 0 },
        placeSouhaitee: r.nombreMembres,
        signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
      },
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
    const signature = await usurpateur.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id, 3));
    const r = await client.requete("POST", `/cercles/${cercle.id}/adhesions`, { placeSouhaitee: 3, signature }, m);
    expect(r.status).toBe(403);
  });

  it("quand le cercle est complet, l'ordre est figé selon le score", async () => {
    const org = await client.inscrire();
    const cercle = (await (await creerCercle(org, reglement())).json()) as Cercle;
    const [a, b] = [await client.inscrire(), await client.inscrire()];
    await adherer(cercle, a);
    const complet = (await (await adherer(cercle, b)).json()) as Cercle;
    expect(complet.statut).toBe("complet");
    // Tous à 0, tous ont demandé la dernière place : le premier inscrit l'obtient, les suivants prennent
    // les places restantes dans l'ordre d'inscription (choix de David, 08/11).
    expect(complet.ordre!.map((p) => p.membreId)).toEqual([a.id, b.id, org.id]);
    expect(complet.ordre!.map((p) => p.placeSouhaitee)).toEqual([3, 3, 3]);
    expect((await adherer(cercle, await client.inscrire())).status).toBe(400);
  });

  it("la place souhaitée fait partie de l'engagement signé : une autre place que celle signée est refusée", async () => {
    // Cercle de 6 : un nouveau peut demander la 5 ou la 6. Il signe la 6 et envoie la 5.
    const cercle = (await (
      await creerCercle(await client.inscrire(), reglement({ nombreMembres: 6 }))
    ).json()) as Cercle;
    const m = await client.inscrire();
    const signature = await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id, 6));
    const r = await client.requete("POST", `/cercles/${cercle.id}/adhesions`, { placeSouhaitee: 5, signature }, m);
    expect(r.status).toBe(403);
  });

  it("place plus tôt que ce que permet le score, ou hors du cercle : refusée avec la première place permise", async () => {
    const cercle = (await (await creerCercle(await client.inscrire(), reglement())).json()) as Cercle;
    const nouveau = await client.inscrire();
    const tot = await adherer(cercle, nouveau, 1);
    expect(tot.status).toBe(400);
    expect(((await tot.json()) as { message: string }).message).toMatch(/à partir de la 3e/);
    expect((await adherer(cercle, nouveau, 4)).status).toBe(400);
    expect((await adherer(cercle, nouveau, 3)).status).toBe(201);
  });

  it("l'organisateur aussi : sa place est signée avec le règlement et contrôlée par son score", async () => {
    const org = await client.inscrire();
    const r = reglement();
    const tot = await client.requete(
      "POST",
      "/cercles",
      { reglement: r, placeSouhaitee: 1, signature: await org.signer(messageReglement(org.id, r, 1)) },
      org,
    );
    expect(tot.status).toBe(400);
    const autrePlace = await client.requete(
      "POST",
      "/cercles",
      { reglement: r, placeSouhaitee: 3, signature: await org.signer(messageReglement(org.id, r, 2)) },
      org,
    );
    expect(autrePlace.status).toBe(403);
  });

  it("un non-membre voit la première place que son score lui permet de demander", async () => {
    const cercle = (await (await creerCercle(await client.inscrire(), reglement())).json()) as Cercle;
    const vu = await client.requete("GET", `/cercles/${cercle.id}`, undefined, await client.inscrire());
    expect(((await vu.json()) as { premierePlaceAutorisee: number }).premierePlaceAutorisee).toBe(3);
  });
});
