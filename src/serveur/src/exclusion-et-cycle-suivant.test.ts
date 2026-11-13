import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, cercleComplet, cotisationsDe, creerCercle, dansJours, reglementDeTest } from "./testing/cercles.js";

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
const HEURE_MS = 60 * 60 * 1000;

/** Événements de score fictifs, pour construire un historique sans jouer des dizaines de cercles. */
async function historique(membre: Identite, ...types: string[]) {
  for (const type of types) {
    await base.requete("INSERT INTO score.evenements (membre_id, type, cercle_id, date) VALUES ($1, $2, $3, now())", [
      membre.id,
      type,
      randomUUID(),
    ]);
  }
}
const vingtQuatreATemps = Array.from({ length: 24 }, () => "cotisation_a_temps");

describe("premières places fermées après un défaut (S3)", () => {
  it("un membre au bon score mais en défaut récent ne peut pas demander la place 1, et le sait", async () => {
    const surveille = await client.inscrire();
    await historique(surveille, ...vingtQuatreATemps, "defaut"); // 96 − 30 = 66 : assez pour le début, sans le défaut
    const s = await json<{ score: number; premieresPlacesFermees: boolean; explication: string[] }>(
      await client.requete("GET", `/score/${surveille.id}`, undefined, surveille),
    );
    expect(s).toMatchObject({ score: 66, premieresPlacesFermees: true });
    expect(s.explication.join(" ")).toMatch(/deux cycles terminés sans défaut/);

    const org = await client.inscrire();
    const cercle = await json<Cercle>(await creerCercle(client, org, reglementDeTest({ nombreMembres: 6 })));
    const vu = await json<{ premierePlaceAutorisee: number }>(
      await client.requete("GET", `/cercles/${cercle.id}`, undefined, surveille),
    );
    expect(vu.premierePlaceAutorisee).toBe(3);
    const r = await adherer(client, cercle, surveille, 1);
    expect(r.status).toBe(400);
    expect((await json<{ message: string }>(r)).message).toMatch(/défaut/);
    expect((await adherer(client, cercle, surveille, 3)).status).toBe(201);
  });

  it("le même score sans défaut ouvre la place 1 ; deux cycles terminés depuis le défaut la rouvrent", async () => {
    const sain = await client.inscrire();
    await historique(sain, ...vingtQuatreATemps.slice(0, 17)); // 68
    const repenti = await client.inscrire();
    await historique(repenti, ...vingtQuatreATemps, "defaut", "cycle_termine", "cycle_termine");
    const org = await client.inscrire();
    const cercle = await json<Cercle>(await creerCercle(client, org, reglementDeTest({ nombreMembres: 6 })));
    expect((await adherer(client, cercle, sain, 1)).status).toBe(201);
    expect((await adherer(client, cercle, repenti, 2)).status).toBe(201);
  });

  it("à la complétion, l'attribution ne met jamais en tête un membre dont les premières places sont fermées", async () => {
    // Trois membres : l'organisateur, un bon payeur et un membre qui fait défaut après avoir adhéré.
    const [org, bon, fautif] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    await historique(bon, ...vingtQuatreATemps.slice(0, 16)); // 64
    await historique(fautif, ...vingtQuatreATemps); // 96
    const cercle = await json<Cercle>(await creerCercle(client, org, reglementDeTest()));
    await adherer(client, cercle, fautif, 1);
    await historique(fautif, "defaut"); // défaut ailleurs, avant la complétion : 66, premières places fermées
    // Les deux demandent la place 1 : le fautif a le meilleur score, mais ses premières places sont fermées.
    await adherer(client, cercle, bon, 1);
    const complet = await json<Cercle>(await client.requete("GET", `/cercles/${cercle.id}`, undefined, org));
    expect(complet.ordre![0]!.membreId).toBe(bon.id);
    expect(complet.ordre!.find((p) => p.membreId === fautif.id)!.position).toBeGreaterThan(1);
  });
});

describe("cycle suivant : l'organisateur relance son cercle terminé", () => {
  async function cercleTermine() {
    const { membres, org, cercle } = await cercleComplet(client);
    const toutes = (await Promise.all(membres.map((m) => cotisationsDe(client, cercle.id, m)))).flat();
    const fin = Math.max(...toutes.map((c) => Date.parse(c.finGrace)));
    await app.get(PlanificateurService).examinerEcheances(new Date(fin + HEURE_MS));
    return { membres, org, cercle };
  }
  const relancer = async (org: Identite, precedentId: string, extra: Partial<Reglement> = {}) => {
    const reglement = reglementDeTest({ datePremierTour: dansJours(10), ...extra });
    return client.requete(
      "POST",
      "/cercles",
      {
        reglement,
        placeSouhaitee: reglement.nombreMembres,
        cerclePrecedentId: precedentId,
        signature: await org.signer(messageReglement(org.id, reglement, reglement.nombreMembres)),
      },
      org,
    );
  };

  it("le nouveau cercle garde la trace du précédent et ses anciens membres sont invités par SMS", async () => {
    const { membres, org, cercle } = await cercleTermine();
    const r = await relancer(org, cercle.id);
    expect(r.status).toBe(201);
    const suivant = await json<Cercle & { cerclePrecedentId?: string }>(r);
    expect(suivant).toMatchObject({ cerclePrecedentId: cercle.id, statut: "en_attente" });
    await app.get(FileSms).vider();
    for (const m of membres.filter((x) => x !== org)) {
      const numero = (await json<{ numero: string }>(await client.requete("GET", "/comptes/moi", undefined, m))).numero;
      const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages.filter((x) => x.numero === numero);
      expect(sms.at(-1)!.texte).toContain(suivant.id);
    }
    // Un ancien membre en défaut dans le premier cycle ne pourra pas prendre la tête du suivant : c'est la règle S3.
  });

  it("seulement depuis un cercle terminé, et par son organisateur", async () => {
    const { membres, org, cercle } = await cercleComplet(client);
    expect((await relancer(org, cercle.id)).status).toBe(400);
    const termine = await cercleTermine();
    expect((await relancer(membres[1]!, termine.cercle.id)).status).toBe(403);
    expect((await relancer(org, randomUUID())).status).toBe(404);
  });
});
