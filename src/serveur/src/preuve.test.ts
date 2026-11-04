import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import type { Reglement } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import type { DossierDePreuve } from "./modules/preuve/preuve.service.js";
import { calculerMontantDu } from "./modules/preuve/montants.js";
import { RegistreService } from "./registre/registre.service.js";
import { verifierPreuve } from "./registre/merkle.js";
import { verifierSignature } from "./signature/signature.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, dansJours } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const reglement: Reglement = {
  montant: 10000,
  frequence: "hebdomadaire",
  nombreMembres: 3,
  penaliteRetard: 500,
  delaiGraceJours: 2,
  ouvert: false,
  datePremierTour: dansJours(7),
};

/** Un cercle complet de trois, où « defaillant » doit ses deux cotisations générées (une par autre membre). */
async function scenarioDefaut() {
  const { membres, cercle } = await cercleComplet(client, reglement);
  const [org, beneficiaire, defaillant] = membres as [Identite, Identite, Identite];
  // Constat après la fin de grâce du deuxième tour : ses deux cotisations sont échues.
  const finGrace = Math.max(...(await cotisationsDe(client, cercle.id, defaillant)).map((c) => Date.parse(c.finGrace)));
  await app.get(PlanificateurService).constaterDefaut(cercle.id, defaillant.id, 2, new Date(finGrace + 1000));
  return { org, beneficiaire, defaillant, cercle };
}

const dossier = (cercleId: string, debiteur: Identite, demandeur: Identite) =>
  client.requete("GET", `/preuve/cercles/${cercleId}/membres/${debiteur.id}/dossier`, undefined, demandeur);

describe("montant dû dans une mise en demeure", () => {
  it("cotisations non confirmées plus une pénalité de retard du règlement par cotisation", () => {
    expect(calculerMontantDu([10000, 10000], 500)).toEqual({ cotisations: 20000, penalites: 1000, total: 21000 });
  });

  it("aucune cotisation due : rien à réclamer", () => {
    expect(calculerMontantDu([], 500)).toEqual({ cotisations: 0, penalites: 0, total: 0 });
  });
});

describe("dossier de preuve", () => {
  it("un membre lésé exporte un dossier complet et vérifiable", async () => {
    const { beneficiaire, defaillant, cercle } = await scenarioDefaut();
    const r = await dossier(cercle.id, defaillant, beneficiaire);
    expect(r.status).toBe(200);
    const d = (await r.json()) as DossierDePreuve;

    expect(d.debiteur).toMatchObject({ id: defaillant.id, niveauIdentite: 1 });
    expect(d.reglement.contenu).toEqual(reglement);
    expect(d.releveCotisations).toHaveLength(2);
    expect(d.misesEnDemeure).toHaveLength(1);
    expect(d.misesEnDemeure[0]).toMatchObject({ montantDu: { cotisations: 20000, penalites: 1000, total: 21000 } });
    expect(d.reconnaissanceDeDette).toBeNull();
    expect(d.avertissements.join(" ")).toMatch(/avocat/);

    // L'engagement du débiteur se vérifie avec sa seule clé publique.
    expect(verifierSignature(d.debiteur.clePublique, d.engagement.message, d.engagement.signature)).toBe(true);
  });

  it("le débiteur ne peut pas exporter le dossier contre lui-même, un étranger au cercle non plus", async () => {
    const { defaillant, cercle } = await scenarioDefaut();
    expect((await dossier(cercle.id, defaillant, defaillant)).status).toBe(403);
    expect((await dossier(cercle.id, defaillant, await client.inscrire())).status).toBe(403);
  });

  it("pas de dossier contre un membre sans défaut constaté", async () => {
    const { org, beneficiaire, cercle } = await scenarioDefaut();
    expect((await dossier(cercle.id, beneficiaire, org)).status).toBe(404);
  });

  it("rejouer le constat de défaut ne crée pas une seconde mise en demeure", async () => {
    const { beneficiaire, defaillant, cercle } = await scenarioDefaut();
    await app.get(PlanificateurService).constaterDefaut(cercle.id, defaillant.id, 2);
    const d = (await (await dossier(cercle.id, defaillant, beneficiaire)).json()) as DossierDePreuve;
    expect(d.misesEnDemeure).toHaveLength(1);
  });

  it("l'empreinte du dossier et de la mise en demeure partent au registre, avec une preuve vérifiable", async () => {
    const { beneficiaire, defaillant, cercle } = await scenarioDefaut();
    const d = (await (await dossier(cercle.id, defaillant, beneficiaire)).json()) as DossierDePreuve & {
      empreinte: string;
    };
    const registre = app.get(RegistreService);
    await registre.fermerLot();
    for (const e of [d.empreinte, d.misesEnDemeure[0]!.empreinte]) {
      const p = (await registre.preuvePour(e))!;
      expect(verifierPreuve(e, p.etapes, p.racine)).toBe(true);
    }
  });
});
