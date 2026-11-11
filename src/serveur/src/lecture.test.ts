import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import type { Litige } from "./modules/litiges/litiges.service.js";
import { creerClient } from "./testing/client.js";
import { cercleComplet, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;

describe("mon compte", () => {
  it("rend mes données, sans la clé publique", async () => {
    const moi = await client.inscrire();
    const r = await client.requete("GET", "/comptes/moi", undefined, moi);
    expect(r.status).toBe(200);
    const compte = await json<Record<string, unknown>>(r);
    expect(compte).toMatchObject({ id: moi.id, niveau: 1 });
    expect(compte.numero).toMatch(/^\+237/);
    expect(compte.nom).toMatch(/^Membre/);
    expect(compte).not.toHaveProperty("clePublique");
  });

  it("refuse une requête non signée", async () => {
    expect((await client.requete("GET", "/comptes/moi")).status).toBe(401);
  });
});

describe("mes cercles", () => {
  it("liste les cercles où je suis membre, avec ma place, et rien des cercles des autres", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const moi = membres[1]!;
    const etranger = await client.inscrire();
    const enAttente = await json<{ id: string }>(await creerCercle(client, moi, reglementDeTest()));

    const miens = await json<Record<string, unknown>[]>(await client.requete("GET", "/cercles", undefined, moi));
    expect(miens.map((c) => c.id).sort()).toEqual([cercle.id, enAttente.id].sort());
    const complet = miens.find((c) => c.id === cercle.id)!;
    expect(complet).toMatchObject({
      statut: "complet",
      organisateur: false,
      nombreInscrits: 3,
      maPlace: cercle.ordre!.find((p) => p.membreId === moi.id)!.position,
    });
    expect(complet.reglement).toMatchObject({ montant: 10000 });
    // Jamais la liste des membres dans ce résumé : elle se lit cercle par cercle.
    expect(complet).not.toHaveProperty("membres");
    const attente = miens.find((c) => c.id === enAttente.id)!;
    expect(attente).toMatchObject({ statut: "en_attente", organisateur: true, nombreInscrits: 1 });
    expect(attente).not.toHaveProperty("maPlace");

    expect(await json(await client.requete("GET", "/cercles", undefined, etranger))).toEqual([]);
  });

  it("refuse une requête non signée", async () => {
    expect((await client.requete("GET", "/cercles")).status).toBe(401);
  });
});

describe("mes litiges", () => {
  it("liste les litiges où je suis partie, pas ceux des autres", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
    const [payeur, tiers] = membres.filter((m) => m !== beneficiaire);
    const cotisation = (await cotisationsDe(client, cercle.id, payeur!)).find((c) => c.tour === 1)!;
    await client.requete("POST", `/cotisations/${cotisation.id}/paiement`, { referenceTransaction: "OM-1" }, payeur);
    const ouvert = await client.requete(
      "POST",
      "/litiges",
      { cotisationId: cotisation.id, motif: "Rien reçu" },
      beneficiaire,
    );
    expect(ouvert.status).toBe(201);
    const { id } = await json<Litige>(ouvert);

    for (const partie of [payeur!, beneficiaire]) {
      const miens = await json<Litige[]>(await client.requete("GET", "/litiges/miens", undefined, partie));
      expect(miens.map((l) => l.id)).toEqual([id]);
    }
    expect(await json(await client.requete("GET", "/litiges/miens", undefined, tiers))).toEqual([]);
  });

  it("refuse une requête non signée", async () => {
    expect((await client.requete("GET", "/litiges/miens")).status).toBe(401);
  });
});
