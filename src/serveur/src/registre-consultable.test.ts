import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { RegistreService, type RegistreDuCercle } from "./registre/registre.service.js";
import { creerClient } from "./testing/client.js";
import { cercleComplet } from "./testing/cercles.js";

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

async function cercleInscrit() {
  const { membres, org, cercle } = await cercleComplet(client);
  await app.get(RegistreService).fermerLot();
  const lire = async (qui = org) =>
    json<RegistreDuCercle>(await client.requete("GET", `/cercles/${cercle.id}/registre`, undefined, qui));
  return { membres, org, cercle, lire };
}

describe("registre d'un cercle, lisible et vérifiable par ses membres (M10, scénario S8)", () => {
  it("chaque événement du cercle a son empreinte, son lot, sa racine inscrite ; tout est intact", async () => {
    const { lire } = await cercleInscrit();
    const r = await lire();
    const objets = r.evenements.map((e) => e.objet);
    expect(objets).toEqual(expect.arrayContaining(["reglement", "engagement", "ordre"]));
    expect(objets.filter((o) => o === "engagement")).toHaveLength(2);
    for (const e of r.evenements) {
      expect(e.empreinte).toMatch(/^[0-9a-f]{64}$/);
      expect(e.statut).toBe("inscrite");
      expect(e.lot).toMatchObject({ intact: true, inscritSurLaChaine: true });
      expect(e.preuve!.racine).toBe(e.lot!.racine);
    }
    expect(r.documents).toEqual([
      { objet: "reglement", conforme: true },
      { objet: "ordre", conforme: true },
      { objet: "engagements", conforme: true },
    ]);
    expect(r.integre).toBe(true);
  });

  it("une empreinte modifiée à la main dans le registre est détectée", async () => {
    const { cercle, lire } = await cercleInscrit();
    await base.requete(
      `UPDATE registre.empreintes SET empreinte = repeat('0', 64)
       WHERE id = (SELECT min(id) FROM registre.empreintes WHERE cercle_id = $1)`,
      [cercle.id],
    );
    const r = await lire();
    expect(r.integre).toBe(false);
    expect(r.evenements.some((e) => e.statut === "alteree")).toBe(true);
  });

  it("un lot dont on a aussi réécrit la racine ne correspond plus à ce qui est sur la chaîne", async () => {
    const { cercle, lire } = await cercleInscrit();
    await base.requete(
      `UPDATE registre.lots SET racine = repeat('f', 64)
       WHERE id = (SELECT lot_id FROM registre.empreintes WHERE cercle_id = $1 LIMIT 1)`,
      [cercle.id],
    );
    const r = await lire();
    expect(r.integre).toBe(false);
    expect(r.evenements.some((e) => e.lot && !e.lot.inscritSurLaChaine)).toBe(true);
  });

  it("un règlement ou un ordre retouché en base ne correspond plus à l'empreinte inscrite", async () => {
    const { cercle, lire } = await cercleInscrit();
    await base.requete(`UPDATE cercles.cercles SET reglement = jsonb_set(reglement, '{montant}', '1') WHERE id = $1`, [
      cercle.id,
    ]);
    await base.requete(
      `UPDATE cercles.cercles SET ordre = (SELECT jsonb_agg(x) FROM jsonb_array_elements(ordre) x) WHERE id = $1`,
      [cercle.id],
    );
    const r = await lire();
    expect(r.documents).toContainEqual({ objet: "reglement", conforme: false });
    expect(r.integre).toBe(false);
  });

  it("avant la fermeture du lot : en attente, pas encore inscrit, mais pas altéré", async () => {
    const { org, cercle } = await cercleComplet(client);
    const r = await json<RegistreDuCercle>(
      await client.requete("GET", `/cercles/${cercle.id}/registre`, undefined, org),
    );
    expect(r.evenements.every((e) => e.statut === "en_attente")).toBe(true);
    expect(r.integre).toBe(true);
  });

  it("réservé aux membres du cercle ; requête signée", async () => {
    const { cercle } = await cercleInscrit();
    const etranger = await client.inscrire();
    expect((await client.requete("GET", `/cercles/${cercle.id}/registre`, undefined, etranger)).status).toBe(403);
    expect((await client.requete("GET", `/cercles/${cercle.id}/registre`)).status).toBe(401);
  });
});
