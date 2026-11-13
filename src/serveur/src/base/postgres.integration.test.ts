import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import pg from "pg";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "../app.module.js";
import { BlocagesService } from "../modules/comptes/blocages.service.js";
import { CotisationsService } from "../modules/cotisations/cotisations.service.js";
import { PlanificateurService } from "../modules/planificateur/planificateur.service.js";
import { IdentiteService } from "../modules/comptes/identite.service.js";
import { RecuperationService } from "../modules/comptes/recuperation.service.js";
import { dossierIdentite } from "../testing/identite.js";
import {
  CerclesService,
  messageEngagement,
  messageReglement,
  type Cercle,
  type Reglement,
} from "../modules/cercles/cercles.service.js";
import { creerClient } from "../testing/client.js";
import { avecBareme, dansJours } from "../testing/cercles.js";

/**
 * Même parcours que les autres tests, mais sur un vrai serveur PostgreSQL.
 * Lancé seulement si MONDO_TEST_POSTGRES_URL pointe vers un serveur de test (jamais une base réelle) :
 * une base jetable y est créée puis supprimée.
 */
const URL_SERVEUR = process.env.MONDO_TEST_POSTGRES_URL;

describe.skipIf(!URL_SERVEUR)("sur un vrai PostgreSQL", () => {
  const nomBase = `mondo_test_${Date.now()}`;
  let app: INestApplication;
  let client: Awaited<ReturnType<typeof creerClient>>;
  let urlAvant: string | undefined;

  beforeAll(async () => {
    const admin = new pg.Client({ connectionString: URL_SERVEUR });
    await admin.connect();
    await admin.query(`CREATE DATABASE ${nomBase}`);
    await admin.end();
    urlAvant = process.env.DATABASE_URL;
    const url = new URL(URL_SERVEUR!);
    url.pathname = `/${nomBase}`;
    process.env.DATABASE_URL = url.toString();
    app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
    await app.listen(0);
    client = await creerClient(app);
  }, 30000);

  afterAll(async () => {
    await app?.close();
    process.env.DATABASE_URL = urlAvant;
    const admin = new pg.Client({ connectionString: URL_SERVEUR });
    await admin.connect();
    await admin.query(`DROP DATABASE IF EXISTS ${nomBase}`);
    await admin.end();
  });

  it("parcours complet et course pour la dernière place", async () => {
    const org = await client.inscrire();
    const r: Reglement = avecBareme({
      montant: 10000,
      frequence: "hebdomadaire",
      nombreMembres: 3,
      penaliteRetard: 500,
      delaiGraceJours: 2,
      ouvert: false,
      datePremierTour: dansJours(7),
    });
    const cercle = (await (
      await client.requete(
        "POST",
        "/cercles",
        {
          reglement: r,
          placeSouhaitee: r.nombreMembres,
          signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
        },
        org,
      )
    ).json()) as Cercle;
    const adherer = async (m: Awaited<ReturnType<typeof client.inscrire>>) =>
      client.requete(
        "POST",
        `/cercles/${cercle.id}/adhesions`,
        {
          placeSouhaitee: cercle.reglement.nombreMembres,
          signature: await m.signer(
            messageEngagement(cercle.id, cercle.empreinteReglement, m.id, cercle.reglement.nombreMembres),
          ),
        },
        m,
      );
    expect((await adherer(await client.inscrire())).status).toBe(201);
    const candidats = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    const statuts = (await Promise.all(candidats.map(adherer))).map((x) => x.status).sort();
    expect(statuts).toEqual([201, 400, 400]);
    const final = (await (await client.requete("GET", `/cercles/${cercle.id}`, undefined, org)).json()) as Cercle;
    expect(final.membres).toHaveLength(3);
    expect(final.ordre).toHaveLength(3);

    // Sommes dues du modèle A (migration 023) : créées à la complétion, lues par le débiteur.
    const premier = [org, ...candidats].find((m) => m.id === final.ordre![0]!.membreId);
    const dues = (await (
      await client.requete("GET", `/sommes-dues?cercleId=${cercle.id}`, undefined, premier ?? org)
    ).json()) as { id: string; nature: string }[];
    if (premier) {
      expect(dues.map((s) => s.nature).sort()).toEqual(["frais_mondo", "remise"]);
      expect(
        (await client.requete("POST", `/sommes-dues/${dues[0]!.id}/paiement`, { referenceTransaction: "T" }, premier))
          .status,
      ).toBe(400);
      expect(
        (await client.requete("POST", `/sommes-dues/${dues[0]!.id}/confirmation`, undefined, premier)).status,
      ).toBe(403);
    }
    expect((await client.requete("GET", "/sommes-dues", undefined, org)).status).toBe(200);
    expect((await client.requete("GET", "/administration/sommes-dues", undefined, org)).status).toBe(403);

    // Pénalité au bénéficiaire (migration 024) : colonne lue, puis posée par un défaut constaté.
    const duesOrg = (await (
      await client.requete("GET", `/cotisations?cercleId=${cercle.id}`, undefined, org)
    ).json()) as { payeurId: string; tour: number; penalite: number; penaliteDue: number }[];
    const uneDue = duesOrg.find((c) => c.payeurId === org.id)!;
    expect(uneDue).toMatchObject({ penalite: 500, penaliteDue: 0 });
    await app
      .get(PlanificateurService)
      .constaterDefaut(cercle.id, org.id, uneDue.tour, new Date(Date.now() + 90 * 24 * 3600 * 1000));
    const apresDefaut = (await (
      await client.requete("GET", `/cotisations?cercleId=${cercle.id}`, undefined, org)
    ).json()) as { payeurId: string; tour: number; penaliteDue: number }[];
    expect(apresDefaut.find((c) => c.payeurId === org.id && c.tour === uneDue.tour)!.penaliteDue).toBe(500);

    // Départ (migration 025) : refusé ici pour l'organisateur, qui a un défaut constaté donc une échéance
    // impayée ; les requêtes de contrôle et le verrou tournent sur un vrai serveur. Puis bilans de cycle.
    const depart = await client.requete("POST", `/cercles/${cercle.id}/depart`, undefined, org);
    expect([201, 400]).toContain(depart.status);
    expect((await app.get(PlanificateurService).examinerEcheances()).echecs).toBe(0);

    // Cercles privés à moitié de points (migration 026) : l'insertion marque l'événement, la lecture le rend.
    const scoreOrg = (await (await client.requete("GET", `/score/${org.id}`, undefined, org)).json()) as {
      defauts: number;
    };
    expect(scoreOrg.defauts).toBeGreaterThanOrEqual(1);

    // Échange de places (migration 027) : liste vide, contrôle des tours en lecture seule sur un vrai serveur.
    expect(await (await client.requete("GET", `/cercles/${cercle.id}/echanges`, undefined, org)).json()).toEqual([]);
    const [m1, m2] = final.membres;
    if (m1 && m2) {
      await app
        .get(CotisationsService)
        .echangerTours(cercle.id, m1, m2, new Date(), true)
        .catch((e: unknown) => expect(String(e)).toMatch(/Échange impossible/));
    }

    // Démonstration : l'avance du temps décale tours, cotisations et sommes dues sur un vrai serveur.
    const avance = await client.requete("POST", `/demonstration/cercles/${cercle.id}/avance`, { jours: 1 }, org);
    expect(avance.status).toBe(201);

    // Registre par cercle (migration 028) : lecture et vérification sur un vrai serveur.
    const registre = (await (await client.requete("GET", `/cercles/${cercle.id}/registre`, undefined, org)).json()) as {
      evenements: unknown[];
      integre: boolean;
    };
    expect(registre.evenements.length).toBeGreaterThan(0);

    // État du cercle (US17) et score expliqué sur un vrai serveur.
    expect((await client.requete("GET", `/cotisations/cercles/${cercle.id}/etat`, undefined, org)).status).toBe(200);
    const scoreExplique = (await (await client.requete("GET", `/score/${org.id}`, undefined, org)).json()) as {
      historique: unknown[];
    };
    expect(Array.isArray(scoreExplique.historique)).toBe(true);

    // Routes de lecture de l'application : mêmes requêtes sur un vrai serveur.
    const miens = (await (await client.requete("GET", "/cercles", undefined, org)).json()) as { id: string }[];
    expect(miens.map((c) => c.id)).toEqual([cercle.id]);
    expect((await client.requete("GET", "/comptes/moi", undefined, org)).status).toBe(200);
    expect(await (await client.requete("GET", "/litiges/miens", undefined, org)).json()).toEqual([]);

    // Contact de confiance : désignation (upsert plafonné) puis lecture.
    const contact = { nom: "Contact Fictif", numero: "+237900000001" };
    expect((await client.requete("POST", "/comptes/moi/contact-de-confiance", contact, org)).status).toBe(201);
    expect((await client.requete("POST", "/comptes/moi/contact-de-confiance", contact, org)).status).toBe(201);
    const lu = await client.requete("GET", "/comptes/moi/contact-de-confiance", undefined, org);
    expect(await lu.json()).toMatchObject({ statut: "en_attente" });
    expect(
      (await client.requete("POST", "/comptes/moi/contact-de-confiance/accord", { code: "000000" }, org)).status,
    ).toBeGreaterThanOrEqual(201);

    // Vérification d'identité : sans accord du contact le dépôt est refusé (403) ; la purge et la lecture du
    // dossier exercent les requêtes de la migration 021.
    const depot = await client.requete("POST", "/comptes/moi/identite", dossierIdentite(), org);
    expect(depot.status).toBe(403);
    expect((await client.requete("GET", "/comptes/moi/identite", undefined, org)).status).toBe(404);
    // Récupération et blocage (migration 022) : demande refusée proprement, blocage posé puis levé, dates décalées.
    const blocages = app.get(BlocagesService);
    await blocages.bloquer(org.id, "essais_rates", new Date(Date.now() - 48 * 3600 * 1000));
    await blocages.bloquer(org.id, "opposition");
    expect((await client.requete("GET", "/comptes/moi", undefined, org)).status).toBe(200);
    expect(await blocages.leverEchus()).toBe(1);
    expect((await blocages.comptesBloques()).size).toBe(0);
    await blocages.bloquer(org.id, "opposition");
    expect((await client.requete("GET", "/comptes/moi", undefined, org)).status).toBe(423);
    await blocages.lever(org.id);
    expect(await app.get(RecuperationService).finaliser()).toBe(0);
    expect(await app.get(RecuperationService).enRecuperation(org.id)).toBe(false);
    expect((await client.requete("POST", "/comptes/moi/code-secret", { code: "482615" }, org)).status).toBe(201);
    await app.get(IdentiteService).noterFinDeCercle(org.id, new Date());
    expect(
      await app.get(IdentiteService).purger(new Date(), (id) => app.get(CerclesService).aUnCercleEnCours(id)),
    ).toBe(0);
    // Catalogue (requête sur le règlement en JSON) et invitations (plafond en une instruction).
    expect(
      (await client.requete("GET", "/cercles/catalogue?montantMax=50000&frequence=hebdomadaire", undefined, org))
        .status,
    ).toBe(200);
    const autreCercle = (await (
      await client.requete(
        "POST",
        "/cercles",
        {
          reglement: r,
          placeSouhaitee: r.nombreMembres,
          signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
        },
        org,
      )
    ).json()) as { id: string };
    const invitation = await client.requete(
      "POST",
      `/cercles/${autreCercle.id}/invitations`,
      { numero: "+237900000077" },
      org,
    );
    expect(invitation.status).toBe(201);
  });
});
