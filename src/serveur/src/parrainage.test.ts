import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { EvenementsInternes } from "./evenements/evenements-internes.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let base: BaseDeDonnees;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
  base = app.get<BaseDeDonnees>(BASE_DE_DONNEES);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;

async function evenements(membre: Identite, ...types: string[]) {
  for (const type of types) {
    await base.requete("INSERT INTO score.evenements (membre_id, type, cercle_id, date) VALUES ($1, $2, $3, now())", [
      membre.id,
      type,
      randomUUID(),
    ]);
  }
}
/** Membre fiable : score 40 (dix cotisations à temps en cercle ouvert). */
async function membreFiable() {
  const m = await client.inscrire();
  await evenements(m, ...Array.from({ length: 10 }, () => "cotisation_a_temps"));
  return m;
}
interface Parrainage {
  id: string;
  parrainId: string;
  filleulId: string;
  statut: "propose" | "accepte" | "refuse";
}
const proposer = (parrain: Identite, filleul: Identite) =>
  client.requete("POST", "/comptes/moi/parrainages", { filleulId: filleul.id }, parrain);
const accepter = (p: Parrainage, qui: Identite) =>
  client.requete("POST", `/comptes/moi/parrainages/${p.id}/acceptation`, undefined, qui);
const score = async (qui: Identite) =>
  (await json<{ score: number }>(await client.requete("GET", `/score/${qui.id}`, undefined, qui))).score;

describe("parrainage (cahier des charges, US6) : un membre fiable parraine un proche, sans caution", () => {
  it("le parrain propose, le filleul accepte ; chacun voit le parrainage", async () => {
    const [parrain, filleul] = [await membreFiable(), await client.inscrire()];
    const r = await proposer(parrain, filleul);
    expect(r.status).toBe(201);
    const p = await json<Parrainage>(r);
    expect(p).toMatchObject({ statut: "propose", parrainId: parrain.id, filleulId: filleul.id });
    expect((await accepter(p, parrain)).status).toBe(403);
    expect(await json(await accepter(p, filleul))).toMatchObject({ statut: "accepte" });
    for (const qui of [parrain, filleul]) {
      const miens = await json<{ commeParrain: Parrainage[]; commeFilleul: Parrainage[] }>(
        await client.requete("GET", "/comptes/moi/parrainages", undefined, qui),
      );
      expect([...miens.commeParrain, ...miens.commeFilleul].map((x) => x.id)).toEqual([p.id]);
    }
  });

  it("seul un membre fiable parraine : score d'au moins 30, sans défaut récent ; trois filleuls au plus ; un parrain par filleul", async () => {
    const debutant = await client.inscrire();
    expect((await proposer(debutant, await client.inscrire())).status).toBe(403);
    const fautif = await client.inscrire();
    await evenements(fautif, ...Array.from({ length: 24 }, () => "cotisation_a_temps"), "defaut");
    expect((await proposer(fautif, await client.inscrire())).status).toBe(403);

    const parrain = await membreFiable();
    expect((await proposer(parrain, parrain)).status).toBe(400);
    for (let i = 0; i < 3; i++) expect((await proposer(parrain, await client.inscrire())).status).toBe(201);
    expect((await proposer(parrain, await client.inscrire())).status).toBe(409);

    const [autreParrain, filleul] = [await membreFiable(), await client.inscrire()];
    const p = await json<Parrainage>(await proposer(autreParrain, filleul));
    await accepter(p, filleul);
    const second = await json<Parrainage>(await proposer(await membreFiable(), filleul));
    expect((await accepter(second, filleul)).status).toBe(409);
    expect((await client.requete("POST", "/comptes/moi/parrainages", { filleulId: filleul.id })).status).toBe(401);
  });

  it("dans un cercle qui accepte le parrainage, le filleul entre sous le seuil si son parrain en est membre", async () => {
    const [parrain, filleul] = [await membreFiable(), await client.inscrire()];
    await accepter(await json<Parrainage>(await proposer(parrain, filleul)), filleul);
    const org = await membreFiable();
    const avec = await json<Cercle>(
      await creerCercle(client, org, reglementDeTest({ nombreMembres: 4, scoreMinimum: 20, parrainageAccepte: true })),
    );
    // Sans le parrain dans le cercle : refusé.
    expect((await adherer(client, avec, filleul)).status).toBe(403);
    expect((await adherer(client, avec, parrain)).status).toBe(201);
    expect((await adherer(client, avec, filleul)).status).toBe(201);
    // Un cercle qui n'a pas signé « parrainage accepté » garde son seuil pour tout le monde.
    const sans = await json<Cercle>(
      await creerCercle(client, org, reglementDeTest({ nombreMembres: 4, scoreMinimum: 20 })),
    );
    await adherer(client, sans, parrain);
    expect((await adherer(client, sans, filleul)).status).toBe(403);
  });

  it("le parrain gagne 2 points quand son filleul termine un cycle sans défaut ; rien ne lui est retiré s'il fait défaut", async () => {
    const [parrain, filleul] = [await membreFiable(), await client.inscrire()];
    await accepter(await json<Parrainage>(await proposer(parrain, filleul)), filleul);
    const avant = await score(parrain);
    const bus = app.get(EvenementsInternes);
    // Un défaut du filleul ne touche que lui : le parrain n'est pas caution.
    await evenements(filleul, "defaut");
    expect(await score(parrain)).toBe(avant);
    await bus.publier({ type: "cycle_termine", cercleId: randomUUID(), membreId: filleul.id });
    expect(await score(parrain)).toBe(avant + 2);
  });
});
