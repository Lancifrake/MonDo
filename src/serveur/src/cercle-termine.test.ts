import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { EvenementsInternes } from "./evenements/evenements-internes.js";
import { CerclesService, type Cercle } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const HEURE_MS = 60 * 60 * 1000;

/** Cercle de trois où personne ne paie : rend la fin de grâce du dernier tour. */
async function cercleSansPaiement() {
  const { membres, org, cercle } = await cercleComplet(client, reglementDeTest());
  const toutes = (await Promise.all(membres.map((m) => cotisationsDe(client, cercle.id, m)))).flat();
  const finDernierTour = Math.max(...toutes.map((c) => Date.parse(c.finGrace)));
  const lire = async () =>
    (await (await client.requete("GET", `/cercles/${cercle.id}`, undefined, org)).json()) as Cercle;
  const score = async (qui: Identite) =>
    ((await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as { defauts: number }).defauts;
  return { membres, cercle, finDernierTour, lire, score, planificateur: app.get(PlanificateurService) };
}

describe("cercle terminé à la fin de grâce du dernier tour", () => {
  it("avant : toujours complet", async () => {
    const { finDernierTour, lire, planificateur } = await cercleSansPaiement();
    await planificateur.examinerEcheances(new Date(finDernierTour - HEURE_MS));
    expect((await lire()).statut).toBe("complet");
  });

  it("après : terminé à la date de fin du dernier tour, même avec des impayés ; les défauts suivent leur cours", async () => {
    const { membres, finDernierTour, lire, score, planificateur } = await cercleSansPaiement();
    await planificateur.examinerEcheances(new Date(finDernierTour + HEURE_MS));
    expect(await lire()).toMatchObject({ statut: "termine", termineLe: new Date(finDernierTour).toISOString() });
    // Chacun paie deux des trois tours (pas le sien) : deux défauts chacun.
    for (const m of membres) expect(await score(m)).toBe(2);
  });

  it("examen rejoué : reste terminé, à la même date", async () => {
    const { finDernierTour, lire, planificateur } = await cercleSansPaiement();
    await planificateur.examinerEcheances(new Date(finDernierTour + HEURE_MS));
    await planificateur.examinerEcheances(new Date(finDernierTour + 30 * HEURE_MS));
    expect(await lire()).toMatchObject({ statut: "termine", termineLe: new Date(finDernierTour).toISOString() });
  });

  it("chaque membre est prévenu de la fin (conservation de sa pièce), et n'a plus de cercle en cours", async () => {
    const { membres, cercle, finDernierTour, planificateur } = await cercleSansPaiement();
    const cercles = app.get(CerclesService);
    const prevenus: string[] = [];
    app.get(EvenementsInternes).ecouter("fin_de_cercle_pour_membre", (e) => {
      if (e.cercleId === cercle.id) prevenus.push(e.membreId);
    });
    expect(await cercles.aUnCercleEnCours(membres[0]!.id)).toBe(true);
    await planificateur.examinerEcheances(new Date(finDernierTour + HEURE_MS));
    await planificateur.examinerEcheances(new Date(finDernierTour + 2 * HEURE_MS));
    expect(prevenus.sort()).toEqual(membres.map((m) => m.id).sort());
    expect(await cercles.aUnCercleEnCours(membres[0]!.id)).toBe(false);
  });
});
