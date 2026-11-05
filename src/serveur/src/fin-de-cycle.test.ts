import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import type { Cotisation } from "./modules/cotisations/cotisations.service.js";
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

const historique = async (qui: Identite) =>
  (await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as {
    cyclesTermines: number;
    defauts: number;
  };

/** Cercle de trois, hebdomadaire. Rend de quoi payer, confirmer et la fin de grâce de chaque tour. */
async function cycle() {
  const { membres, cercle } = await cercleComplet(client, reglementDeTest());
  const parId = new Map(membres.map((m) => [m.id, m]));
  const aPayer = async (m: Identite) => (await cotisationsDe(client, cercle.id, m)).filter((c) => c.payeurId === m.id);
  const declarer = (c: Cotisation) =>
    client.requete(
      "POST",
      `/cotisations/${c.id}/paiement`,
      { referenceTransaction: `OM-${c.id}` },
      parId.get(c.payeurId),
    );
  const confirmer = (c: Cotisation) =>
    client.requete("POST", `/cotisations/${c.id}/confirmation`, undefined, parId.get(c.beneficiaireId));
  const payerTout = async (m: Identite, sauf: (c: Cotisation) => boolean = () => false) => {
    for (const c of await aPayer(m)) {
      if (sauf(c)) continue;
      await declarer(c);
      await confirmer(c);
    }
  };
  const toutes = (await Promise.all(membres.map(aPayer))).flat();
  const finGraceDuTour = (n: number) =>
    Math.max(...toutes.filter((c) => c.tour === n).map((c) => Date.parse(c.finGrace)));
  const apresCycle = new Date(finGraceDuTour(membres.length) + HEURE_MS);
  const planificateur = app.get(PlanificateurService);
  return { membres, aPayer, declarer, confirmer, payerTout, finGraceDuTour, apresCycle, planificateur };
}

describe("fin de cycle : bonus pour le membre sans défaut dont tout est confirmé", () => {
  it("tout payé et confirmé, mais avant la fin de grâce du dernier tour : pas encore de bonus", async () => {
    const { membres, payerTout, finGraceDuTour, planificateur } = await cycle();
    for (const m of membres) await payerTout(m);
    await planificateur.examinerEcheances(new Date(finGraceDuTour(3) - HEURE_MS));
    for (const m of membres) expect((await historique(m)).cyclesTermines).toBe(0);
  });

  it("après la fin de grâce du dernier tour : un cycle terminé pour chacun", async () => {
    const { membres, payerTout, apresCycle, planificateur } = await cycle();
    for (const m of membres) await payerTout(m);
    await planificateur.examinerEcheances(apresCycle);
    for (const m of membres) expect(await historique(m)).toMatchObject({ cyclesTermines: 1, defauts: 0 });
  });

  it("défaut au premier tour, même régularisé ensuite : pas de bonus pour lui, bonus pour les autres", async () => {
    const { membres, aPayer, declarer, confirmer, payerTout, finGraceDuTour, apresCycle, planificateur } =
      await cycle();
    // Le fautif doit payer au premier tour : ce n'est pas le premier bénéficiaire.
    const fautif = membres[membres.length - 1]!;
    expect((await aPayer(fautif)).some((c) => c.tour === 1)).toBe(true);
    const serieux = membres.filter((m) => m !== fautif);
    for (const m of serieux) await payerTout(m);
    await payerTout(fautif, (c) => c.tour === 1);
    await planificateur.examinerEcheances(new Date(finGraceDuTour(1) + HEURE_MS));
    const enRetard = (await aPayer(fautif)).find((c) => c.statut === "due")!;
    await declarer(enRetard);
    await confirmer(enRetard);

    await planificateur.examinerEcheances(apresCycle);
    expect(await historique(fautif)).toMatchObject({ cyclesTermines: 0, defauts: 1 });
    for (const m of serieux) expect((await historique(m)).cyclesTermines).toBe(1);
  });

  it("paiement déclaré mais pas encore confirmé : bonus seulement le jour où la confirmation tombe", async () => {
    const { membres, aPayer, declarer, confirmer, payerTout, apresCycle, planificateur } = await cycle();
    const [attente, ...autres] = membres as [Identite, ...Identite[]];
    for (const m of autres) await payerTout(m);
    const [premiere, ...reste] = await aPayer(attente);
    for (const c of reste) {
      await declarer(c);
      await confirmer(c);
    }
    await declarer(premiere!);

    await planificateur.examinerEcheances(apresCycle);
    expect(await historique(attente)).toMatchObject({ cyclesTermines: 0, defauts: 0 });

    await confirmer(premiere!);
    await planificateur.examinerEcheances(new Date(apresCycle.getTime() + 24 * HEURE_MS));
    expect((await historique(attente)).cyclesTermines).toBe(1);
  });

  it("examen rejoué : un seul bonus par membre et par cercle", async () => {
    const { membres, payerTout, apresCycle, planificateur } = await cycle();
    for (const m of membres) await payerTout(m);
    await planificateur.examinerEcheances(apresCycle);
    await planificateur.examinerEcheances(new Date(apresCycle.getTime() + HEURE_MS));
    await planificateur.examinerEcheances(new Date(apresCycle.getTime() + 48 * HEURE_MS));
    for (const m of membres) expect((await historique(m)).cyclesTermines).toBe(1);
  });
});
