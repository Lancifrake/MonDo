import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
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

const HEURE_MS = 60 * 60 * 1000;
const score = async (qui: Identite) =>
  (
    (await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as {
      score: number;
    }
  ).score;

/** Cercle de trois, ouvert ou privé ; au premier tour un membre paie à temps, l'autre ne paie pas. */
async function premierTour(ouvert: boolean) {
  const inscrits = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
  if (ouvert) for (const m of inscrits) await m.niveau2();
  const membres: Identite[] = inscrits;
  const [org, ...autres] = membres;
  const cree = (await (await creerCercle(client, org!, reglementDeTest({ ouvert }))).json()) as Cercle;
  for (const m of autres) await adherer(client, cree, m);
  const cercle = (await (await client.requete("GET", `/cercles/${cree.id}`, undefined, org)).json()) as Cercle;
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const [ponctuel, defaillant] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
  const due = (await cotisationsDe(client, cercle.id, ponctuel)).find(
    (c) => c.tour === 1 && c.payeurId === ponctuel.id,
  )!;
  await client.requete("POST", `/cotisations/${due.id}/paiement`, { referenceTransaction: "OM-5" }, ponctuel);
  await client.requete("POST", `/cotisations/${due.id}/confirmation`, undefined, beneficiaire);
  return { cercle, ponctuel, defaillant, finGrace: Date.parse(due.finGrace) };
}

describe("cercles privés à moitié de points (choix de David, 11/11)", () => {
  it("cercle ouvert : une cotisation à temps rapporte 4 ; cercle privé : 2", async () => {
    expect(await score((await premierTour(true)).ponctuel)).toBe(4);
    expect(await score((await premierTour(false)).ponctuel)).toBe(2);
  });

  it("les pertes restent entières : un défaut en cercle privé efface autant qu'en cercle ouvert", async () => {
    // Le défaillant gagne d'abord 4 points dans un cercle ouvert, puis fait défaut dans un cercle privé.
    const ouvert = await premierTour(true);
    const prive = await premierTour(false);
    expect(await score(ouvert.ponctuel)).toBe(4);
    await app
      .get(PlanificateurService)
      .constaterDefaut(prive.cercle.id, ouvert.ponctuel.id, 1, new Date(prive.finGrace + HEURE_MS));
    expect(await score(ouvert.ponctuel)).toBe(0);
    // L'événement est bien marqué « cercle privé », et pourtant compté en entier (−30, pas −15) : le calcul
    // pur le vérifie dans score.test.ts ; ici on vérifie le marquage en base.
    const lignes = await app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete<{ type: string; cercle_prive: boolean }>(
        "SELECT type, cercle_prive FROM score.evenements WHERE membre_id = $1 ORDER BY id",
        [ouvert.ponctuel.id],
      );
    expect(lignes).toEqual([
      { type: "cotisation_a_temps", cercle_prive: false },
      { type: "defaut", cercle_prive: true },
    ]);
  });
});
