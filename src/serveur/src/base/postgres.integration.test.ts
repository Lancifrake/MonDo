import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import pg from "pg";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "../app.module.js";
import {
  messageEngagement,
  messageReglement,
  type Cercle,
  type Reglement,
} from "../modules/cercles/cercles.service.js";
import { creerClient } from "../testing/client.js";

/**
 * Même parcours que les autres tests, mais sur un vrai serveur PostgreSQL.
 * Lancé seulement si MONDO_TEST_POSTGRES_URL pointe vers un serveur de test (jamais une base réelle) :
 * une base jetable y est créée puis supprimée.
 */
const URL_SERVEUR = process.env.MONDO_TEST_POSTGRES_URL;

describe.skipIf(!URL_SERVEUR)("sur un vrai PostgreSQL", () => {
  const nomBase = `mondo_test_${Date.now()}`;
  let app: INestApplication;
  let client: Awaited<ReturnType<typeof creerClient>>;
  let urlAvant: string | undefined;

  beforeAll(async () => {
    const admin = new pg.Client({ connectionString: URL_SERVEUR });
    await admin.connect();
    await admin.query(`CREATE DATABASE ${nomBase}`);
    await admin.end();
    urlAvant = process.env.DATABASE_URL;
    const url = new URL(URL_SERVEUR!);
    url.pathname = `/${nomBase}`;
    process.env.DATABASE_URL = url.toString();
    app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
    await app.listen(0);
    client = await creerClient(app);
  }, 30000);

  afterAll(async () => {
    await app?.close();
    process.env.DATABASE_URL = urlAvant;
    const admin = new pg.Client({ connectionString: URL_SERVEUR });
    await admin.connect();
    await admin.query(`DROP DATABASE IF EXISTS ${nomBase}`);
    await admin.end();
  });

  it("parcours complet et course pour la dernière place", async () => {
    const org = await client.inscrire();
    const r: Reglement = {
      montant: 10000,
      frequence: "hebdomadaire",
      nombreMembres: 3,
      penaliteRetard: 500,
      delaiGraceJours: 2,
      ouvert: false,
    };
    const cercle = (await (
      await client.requete(
        "POST",
        "/cercles",
        { reglement: r, signature: await org.signer(messageReglement(org.id, r)) },
        org,
      )
    ).json()) as Cercle;
    const adherer = async (m: Awaited<ReturnType<typeof client.inscrire>>) =>
      client.requete(
        "POST",
        `/cercles/${cercle.id}/adhesions`,
        { signature: await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id)) },
        m,
      );
    expect((await adherer(await client.inscrire())).status).toBe(201);
    const candidats = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    const statuts = (await Promise.all(candidats.map(adherer))).map((x) => x.status).sort();
    expect(statuts).toEqual([201, 400, 400]);
    const final = (await (await client.requete("GET", `/cercles/${cercle.id}`, undefined, org)).json()) as Cercle;
    expect(final.membres).toHaveLength(3);
    expect(final.ordre).toHaveLength(3);
  });
});
