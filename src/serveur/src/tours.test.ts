import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { CotisationsService } from "./modules/cotisations/cotisations.service.js";
import { creerClient } from "./testing/client.js";
import { cercleComplet, cotisationsDe, creerCercle, dansJours, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

const JOUR_MS = 24 * 60 * 60 * 1000;

describe("tours de cotisation générés quand le cercle est complet", () => {
  it("chaque membre paie chaque bénéficiaire sauf lui-même, dans l'ordre de passage, au montant du règlement", async () => {
    const r = reglementDeTest();
    const { membres, cercle } = await cercleComplet(client, r);
    const beneficiaires = cercle.ordre!.map((p) => p.membreId);

    for (const m of membres) {
      const aPayer = (await cotisationsDe(client, cercle.id, m)).filter((c) => c.payeurId === m.id);
      expect(aPayer).toHaveLength(2);
      for (const c of aPayer) {
        expect(c.beneficiaireId).not.toBe(m.id);
        expect(c.beneficiaireId).toBe(beneficiaires[c.tour - 1]);
        expect(c).toMatchObject({ montant: r.montant, statut: "due" });
      }
    }
  });

  it("dates limites : le premier tour à la date du règlement, puis une semaine d'écart ; fin de grâce selon le règlement", async () => {
    const r = reglementDeTest({ delaiGraceJours: 3 });
    const { org, cercle } = await cercleComplet(client, r);
    const parTour = new Map((await cotisationsDe(client, cercle.id, org)).map((c) => [c.tour, c]));
    const premier = Date.parse(r.datePremierTour);
    for (const [tour, c] of parTour) {
      expect(Date.parse(c.dateLimite)).toBe(premier + 7 * (tour - 1) * JOUR_MS);
      expect(Date.parse(c.finGrace)).toBe(Date.parse(c.dateLimite) + 3 * JOUR_MS);
    }
  });

  it("tous les 14 jours : tours espacés de la période choisie par le cercle", async () => {
    const r = reglementDeTest({ frequence: "jours", periodeJours: 14, delaiGraceJours: 3 });
    const { org, cercle } = await cercleComplet(client, r);
    const premier = Date.parse(r.datePremierTour);
    for (const c of await cotisationsDe(client, cercle.id, org)) {
      expect(Date.parse(c.dateLimite)).toBe(premier + 14 * (c.tour - 1) * JOUR_MS);
    }
  });

  it("le bénéficiaire voit ce qu'on lui doit, un autre membre ne voit pas les cotisations des autres", async () => {
    const { cercle, membres } = await cercleComplet(client);
    const premier = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
    const recues = (await cotisationsDe(client, cercle.id, premier)).filter((c) => c.beneficiaireId === premier.id);
    expect(recues).toHaveLength(2);
    expect(recues.every((c) => c.tour === 1)).toBe(true);

    const intrus = await client.inscrire();
    expect(await cotisationsDe(client, cercle.id, intrus)).toEqual([]);
  });

  it("liste sans cercle précisé : refusée", async () => {
    const m = await client.inscrire();
    expect((await client.requete("GET", "/cotisations", undefined, m)).status).toBe(400);
  });

  it("aucune cotisation tant que le cercle n'est pas complet", async () => {
    const org = await client.inscrire();
    const cercle = (await (await creerCercle(client, org, reglementDeTest())).json()) as { id: string };
    expect(await cotisationsDe(client, cercle.id, org)).toEqual([]);
  });

  it("on ne crée plus une cotisation à la main : montant et bénéficiaire viennent du règlement et de l'ordre", async () => {
    const m = await client.inscrire();
    const r = await client.requete(
      "POST",
      "/cotisations",
      { cercleId: "c1", beneficiaireId: m.id, montant: 1, dateLimite: dansJours(1) },
      m,
    );
    expect(r.status).toBe(404);
  });

  it("un règlement dont le premier tour est déjà passé est refusé", async () => {
    const org = await client.inscrire();
    const r = await creerCercle(client, org, reglementDeTest({ datePremierTour: dansJours(-1) }));
    expect(r.status).toBe(400);
  });

  it("événement « cercle complet » rejoué : aucune cotisation en double", async () => {
    const { org, cercle } = await cercleComplet(client);
    const avant = await cotisationsDe(client, cercle.id, org);
    const r = reglementDeTest();
    await app.get(CotisationsService).planifierTours({
      cercleId: cercle.id,
      ordre: cercle.ordre!.map((p) => p.membreId),
      montant: r.montant,
      frequence: r.frequence,
      delaiGraceJours: r.delaiGraceJours,
      datePremierTour: r.datePremierTour,
      completLe: new Date().toISOString(),
    });
    expect(await cotisationsDe(client, cercle.id, org)).toEqual(avant);
  });
});
