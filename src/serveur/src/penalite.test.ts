import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import type { DossierDePreuve } from "./modules/preuve/preuve.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const HEURE_MS = 60 * 60 * 1000;

/** Cercle de trois, hebdomadaire, pénalité de 500 FCFA, deux jours de grâce. */
async function cercle3() {
  const { membres, cercle } = await cercleComplet(client);
  const parPlace = (p: number) => membres.find((m) => m.id === cercle.ordre![p - 1]!.membreId)!;
  const [premier, deuxieme, troisieme] = [parPlace(1), parPlace(2), parPlace(3)];
  const due = async (payeur: Identite, tour: number, vuPar: Identite = payeur) =>
    (await cotisationsDe(client, cercle.id, vuPar)).find((c) => c.tour === tour && c.payeurId === payeur.id)!;
  const payer = async (payeur: Identite, tour: number, beneficiaire: Identite) => {
    const c = await due(payeur, tour);
    await client.requete("POST", `/cotisations/${c.id}/paiement`, { referenceTransaction: "OM-1" }, payeur);
    await client.requete("POST", `/cotisations/${c.id}/confirmation`, undefined, beneficiaire);
  };
  const planificateur = app.get(PlanificateurService);
  const dossier = async (debiteur: Identite, demandeur: Identite) =>
    (await (
      await client.requete("GET", `/preuve/cercles/${cercle.id}/membres/${debiteur.id}/dossier`, undefined, demandeur)
    ).json()) as DossierDePreuve;
  return { cercle, premier, deuxieme, troisieme, due, payer, planificateur, dossier };
}

describe("pénalité de retard, due au bénéficiaire du tour (choix de David, 11/11)", () => {
  it("due à la fin de grâce, une seule fois, au montant du règlement ; rien pour qui a payé", async () => {
    const { premier, deuxieme, troisieme, due, payer, planificateur } = await cercle3();
    await payer(troisieme, 1, premier);
    const avant = await due(deuxieme, 1);
    expect(avant).toMatchObject({ penalite: 500, penaliteDue: 0 });
    expect(avant).not.toHaveProperty("penaliteDueLe");

    // Pendant le délai de grâce : en retard, mais pas encore de pénalité.
    await planificateur.examinerEcheances(new Date(Date.parse(avant.finGrace) - HEURE_MS));
    expect(await due(deuxieme, 1)).toMatchObject({ penaliteDue: 0 });

    await planificateur.examinerEcheances(new Date(Date.parse(avant.finGrace) + HEURE_MS));
    const apres = await due(deuxieme, 1);
    expect(apres).toMatchObject({ penaliteDue: 500, penaliteDueLe: avant.finGrace });
    // Le bénéficiaire du tour la voit dans ce qu'on lui doit ; celui qui a payé n'en doit pas.
    expect(await due(deuxieme, 1, premier)).toMatchObject({ penaliteDue: 500, beneficiaireId: premier.id });
    expect(await due(troisieme, 1)).toMatchObject({ penaliteDue: 0, statut: "confirmee" });

    // Rejoué plus tard : toujours une seule pénalité, à la même date.
    await planificateur.examinerEcheances(new Date(Date.parse(avant.finGrace) + 30 * HEURE_MS));
    expect(await due(deuxieme, 1)).toMatchObject({ penaliteDue: 500, penaliteDueLe: avant.finGrace });
  });

  it("payer après le défaut ne l'efface pas : la pénalité reste due au bénéficiaire", async () => {
    const { premier, deuxieme, due, payer, planificateur } = await cercle3();
    const c = await due(deuxieme, 1);
    await planificateur.examinerEcheances(new Date(Date.parse(c.finGrace) + HEURE_MS));
    await payer(deuxieme, 1, premier);
    expect(await due(deuxieme, 1)).toMatchObject({ statut: "confirmee", penaliteDue: 500 });
  });

  it("mise en demeure : pénalité seulement pour les cotisations dont la grâce est finie, avec le bénéficiaire de chacune", async () => {
    const { premier, deuxieme, troisieme, due, planificateur, dossier } = await cercle3();
    const tour1 = await due(troisieme, 1);
    const tour2 = await due(troisieme, 2);
    // Constat tardif : le tour 2 est échu mais encore dans son délai de grâce.
    const constat = new Date(Date.parse(tour2.dateLimite) + HEURE_MS);
    expect(constat.getTime()).toBeLessThan(Date.parse(tour2.finGrace));
    await planificateur.examinerEcheances(constat);

    const d = await dossier(troisieme, premier);
    expect(d.misesEnDemeure).toHaveLength(1);
    expect(d.misesEnDemeure[0]).toMatchObject({
      tour: 1,
      montantDu: { cotisations: 20000, penalites: 500, total: 20500 },
      lignes: [
        { cotisationId: tour1.id, tour: 1, beneficiaireId: premier.id, montant: 10000, penalite: 500 },
        { cotisationId: tour2.id, tour: 2, beneficiaireId: deuxieme.id, montant: 10000, penalite: 0 },
      ],
    });
    // Le relevé du dossier porte la pénalité, cotisation par cotisation.
    const releve = new Map(d.releveCotisations.map((c) => [c.tour, c.penaliteDue]));
    expect(releve.get(1)).toBe(500);
    expect(releve.get(2)).toBe(0);
  });
});
