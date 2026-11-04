import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import type { DossierDePreuve } from "./modules/preuve/preuve.service.js";
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

const defauts = async (qui: Identite) =>
  ((await (await client.requete("GET", `/score/${qui.id}`, undefined, qui)).json()) as { defauts: number }).defauts;

/**
 * Cercle de quatre. Au premier tour, trois payeurs : l'un paie et c'est confirmé, l'un déclare sans
 * confirmation du bénéficiaire, le dernier ne fait rien.
 */
async function premierTourAvecUnSilencieux() {
  const { membres, cercle } = await cercleComplet(client, reglementDeTest({ nombreMembres: 4, delaiGraceJours: 2 }));
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const [paye, declare, silencieux] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite, Identite];
  const tour1 = async (m: Identite) =>
    (await cotisationsDe(client, cercle.id, m)).find((c) => c.payeurId === m.id && c.tour === 1)!;

  const cPaye = await tour1(paye);
  await client.requete("POST", `/cotisations/${cPaye.id}/paiement`, { referenceTransaction: "OM1" }, paye);
  await client.requete("POST", `/cotisations/${cPaye.id}/confirmation`, undefined, beneficiaire);
  const cDeclare = await tour1(declare);
  await client.requete("POST", `/cotisations/${cDeclare.id}/paiement`, { referenceTransaction: "OM2" }, declare);

  const finGrace = Date.parse(cPaye.finGrace);
  return { cercle, beneficiaire, paye, declare, silencieux, finGrace };
}

describe("défaut constaté automatiquement à la fin du délai de grâce", () => {
  it("dans le délai de grâce : aucun défaut", async () => {
    const { silencieux, finGrace } = await premierTourAvecUnSilencieux();
    await app.get(PlanificateurService).examinerEcheances(new Date(finGrace - HEURE_MS));
    expect(await defauts(silencieux)).toBe(0);
  });

  it("après la fin de grâce : défaut pour celui qui n'a rien payé, pas pour les autres", async () => {
    const { paye, declare, silencieux, finGrace } = await premierTourAvecUnSilencieux();
    await app.get(PlanificateurService).examinerEcheances(new Date(finGrace + HEURE_MS));
    expect(await defauts(silencieux)).toBe(1);
    expect(await defauts(paye)).toBe(0);
    // Paiement déclaré mais pas confirmé : ce n'est pas un défaut du payeur (relève d'un litige).
    expect(await defauts(declare)).toBe(0);
  });

  it("un seul défaut par tour, même si l'examen est rejoué le jour même et les jours suivants", async () => {
    const { silencieux, finGrace } = await premierTourAvecUnSilencieux();
    const planificateur = app.get(PlanificateurService);
    await planificateur.examinerEcheances(new Date(finGrace + HEURE_MS));
    await planificateur.examinerEcheances(new Date(finGrace + 2 * HEURE_MS));
    await planificateur.examinerEcheances(new Date(finGrace + 26 * HEURE_MS));
    expect(await defauts(silencieux)).toBe(1);
  });

  it("la mise en demeure ne réclame que les cotisations échues, pas celles des tours à venir", async () => {
    const { cercle, beneficiaire, silencieux, finGrace } = await premierTourAvecUnSilencieux();
    const constat = new Date(finGrace + HEURE_MS);
    await app.get(PlanificateurService).examinerEcheances(constat);
    const r = await client.requete(
      "GET",
      `/preuve/cercles/${cercle.id}/membres/${silencieux.id}/dossier`,
      undefined,
      beneficiaire,
    );
    const d = (await r.json()) as DossierDePreuve;
    expect(d.misesEnDemeure).toHaveLength(1);
    expect(d.misesEnDemeure[0]).toMatchObject({
      tour: 1,
      emiseLe: constat.toISOString(),
      montantDu: { cotisations: 10000, penalites: 500, total: 10500 },
    });
    expect(d.misesEnDemeure[0]!.cotisationsDues).toHaveLength(1);
  });
});
