import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;

/** Trois nouveaux membres (score 0) ; l'organisateur se place en deuxième. */
async function troisMembres() {
  const [org, b, c] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
  const ordre = [c, org, b];
  const reglement = reglementDeTest({ ordreFixe: ordre.map((m) => m.id) });
  return { org, b, c, ordre, reglement };
}

describe("ordre fixé par l'organisateur en cercle privé", () => {
  it("l'ordre du règlement devient l'ordre de passage, sans regarder le score", async () => {
    const { org, b, c, ordre, reglement } = await troisMembres();
    const cree = await creerCercle(client, org, reglement, 2);
    expect(cree.status).toBe(201);
    const cercle = await json<Cercle>(cree);
    // Un nouveau (score 0) signe la place 1 : permis ici, puisque chacun signe l'ordre en le connaissant.
    expect((await adherer(client, cercle, c, 1)).status).toBe(201);
    expect((await adherer(client, cercle, b, 3)).status).toBe(201);
    const complet = await json<Cercle>(await client.requete("GET", `/cercles/${cercle.id}`, undefined, org));
    expect(complet.statut).toBe("complet");
    expect(complet.ordre!.map((p) => p.membreId)).toEqual(ordre.map((m) => m.id));
    expect(complet.ordre!.map((p) => p.zone)).toEqual(["debut", "milieu", "fin"]);
    // Les tours suivent cet ordre : le premier bénéficiaire est celui que l'organisateur a mis en tête.
    const duesDeOrg = await cotisationsDe(client, cercle.id, org);
    expect(duesDeOrg.find((x) => x.tour === 1)!.beneficiaireId).toBe(c.id);
  });

  it("chacun signe sa place fixée : une autre place est refusée, un membre non prévu aussi", async () => {
    const { org, b, c, reglement } = await troisMembres();
    expect((await creerCercle(client, org, reglement, 3)).status).toBe(400);
    const cercle = await json<Cercle>(await creerCercle(client, org, reglement, 2));
    expect((await adherer(client, cercle, b, 1)).status).toBe(400);
    const intrus = await client.inscrire();
    expect((await adherer(client, cercle, intrus, 3)).status).toBe(403);
    expect((await adherer(client, cercle, b, 3)).status).toBe(201);
    expect((await adherer(client, cercle, c, 1)).status).toBe(201);
  });

  it("interdit en cercle ouvert ; liste complète, sans doublon, avec l'organisateur et des comptes existants", async () => {
    const { org, b, c } = await troisMembres();
    const ids = [c.id, org.id, b.id];
    const essai = (extra: Parameters<typeof reglementDeTest>[0], qui: Identite = org, place = 2) =>
      creerCercle(client, qui, reglementDeTest(extra), place);
    expect((await essai({ ordreFixe: ids, ouvert: true })).status).toBe(400);
    expect((await essai({ ordreFixe: ids.slice(0, 2) })).status).toBe(400);
    expect((await essai({ ordreFixe: [c.id, org.id, org.id] })).status).toBe(400);
    expect((await essai({ ordreFixe: [c.id, b.id, "00000000-0000-4000-8000-000000000000"] })).status).toBe(400);
    expect((await essai({ ordreFixe: [c.id, org.id, "00000000-0000-4000-8000-000000000000"] })).status).toBe(400);
    expect((await essai({ ordreFixe: ["pas-un-uuid", org.id, b.id] })).status).toBe(400);
  });

  it("un membre prévu voit l'ordre et sa place avant de signer ; un inconnu avec le lien ne voit pas l'ordre", async () => {
    const { org, b, reglement } = await troisMembres();
    const cercle = await json<Cercle>(await creerCercle(client, org, reglement, 2));
    const pourB = await json<Record<string, unknown> & { reglement: { ordreFixe?: string[] } }>(
      await client.requete("GET", `/cercles/${cercle.id}`, undefined, b),
    );
    expect(pourB.reglement.ordreFixe).toEqual(reglement.ordreFixe);
    expect(pourB).toMatchObject({ placeFixee: 3 });
    expect(pourB).not.toHaveProperty("membres");
    const inconnu = await client.inscrire();
    const pourInconnu = await json<Record<string, unknown> & { reglement: Record<string, unknown> }>(
      await client.requete("GET", `/cercles/${cercle.id}`, undefined, inconnu),
    );
    expect(pourInconnu.reglement).not.toHaveProperty("ordreFixe");
    expect(pourInconnu).toMatchObject({ ordreFixeParOrganisateur: true });
    expect(pourInconnu).not.toHaveProperty("placeFixee");
    expect(JSON.stringify(pourInconnu)).not.toContain(b.id);
  });
});
