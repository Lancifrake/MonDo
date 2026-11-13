import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, cercleComplet, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let base: BaseDeDonnees;
let suivant = 0;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
  base = app.get<BaseDeDonnees>(BASE_DE_DONNEES);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;
const numeroFictif = () => `+2377${String(process.pid % 10000).padStart(4, "0")}${String(++suivant).padStart(4, "0")}`;

/** Score fictif de 60 : quinze cotisations à temps en cercle ouvert. */
async function noter(membre: Identite, points: number) {
  for (let i = 0; i < points / 4; i++) {
    await base.requete(
      "INSERT INTO score.evenements (membre_id, type, cercle_id, date) VALUES ($1, 'cotisation_a_temps', $2, now())",
      [membre.id, randomUUID()],
    );
  }
}

describe("invitations par numéro (US4)", () => {
  async function cercleEnAttente() {
    const org = await client.inscrire();
    const cercle = await json<Cercle>(await creerCercle(client, org, reglementDeTest({ nombreMembres: 3 })));
    const inviter = (numero: string, qui: Identite = org) =>
      client.requete("POST", `/cercles/${cercle.id}/invitations`, { numero }, qui);
    return { org, cercle, inviter };
  }
  const smsVers = async (numero: string) => {
    await app.get(FileSms).vider();
    return app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages.filter((m) => m.numero === numero);
  };

  it("l'organisateur invite un numéro : un SMS avec l'identifiant du cercle, sans rien garder du numéro en clair", async () => {
    const { cercle, inviter } = await cercleEnAttente();
    const numero = numeroFictif();
    const r = await inviter(numero);
    expect(r.status).toBe(201);
    expect(await json(r)).toMatchObject({ invitationsEnvoyees: 1 });
    const sms = await smsVers(numero);
    expect(sms).toHaveLength(1);
    expect(sms[0]!.texte).toContain(cercle.id);
    expect(sms[0]!.texte).toMatch(/10 000 FCFA/);
    const lignes = await base.requete("SELECT * FROM cercles.invitations WHERE cercle_id = $1", [cercle.id]);
    expect(JSON.stringify(lignes)).not.toContain(numero.slice(1));
    // Le même numéro n'est pas sollicité deux fois.
    expect((await inviter(numero)).status).toBe(201);
    expect(await smsVers(numero)).toHaveLength(1);
  });

  it("réservé à l'organisateur, cercle en attente, plafond d'invitations, corps strict", async () => {
    const { cercle, inviter } = await cercleEnAttente();
    const autre = await client.inscrire();
    expect((await inviter(numeroFictif(), autre)).status).toBe(403);
    expect((await client.requete("POST", `/cercles/${cercle.id}/invitations`, { numero: numeroFictif() })).status).toBe(
      401,
    );
    expect(
      (await client.requete("POST", `/cercles/${cercle.id}/invitations`, { numero: "abc" }, undefined)).status,
    ).toBe(401);
    // Trois fois le nombre de places au plus : 9 pour un cercle de 3.
    for (let i = 0; i < 9; i++) expect((await inviter(numeroFictif())).status).toBe(201);
    expect((await inviter(numeroFictif())).status).toBe(429);
    const { org, cercle: complet } = await cercleComplet(client);
    expect(
      (await client.requete("POST", `/cercles/${complet.id}/invitations`, { numero: numeroFictif() }, org)).status,
    ).toBe(400);
  });
});

describe("seuil de score à l'entrée, fixé par l'organisateur (M3)", () => {
  it("un candidat sous le seuil est refusé avec un message clair ; au-dessus, il entre", async () => {
    const org = await client.inscrire();
    const cercle = await json<Cercle>(await creerCercle(client, org, reglementDeTest({ scoreMinimum: 20 })));
    const nouveau = await client.inscrire();
    const vu = await json<Record<string, unknown>>(
      await client.requete("GET", `/cercles/${cercle.id}`, undefined, nouveau),
    );
    expect(vu).toMatchObject({ scoreSuffisant: false });
    const r = await adherer(client, cercle, nouveau);
    expect(r.status).toBe(403);
    expect((await json<{ message: string }>(r)).message).toMatch(/score \(0\).*seuil.*20/);
    const confirme = await client.inscrire();
    await noter(confirme, 20);
    expect((await adherer(client, cercle, confirme)).status).toBe(201);
  });

  it("seuil entre 0 et 100 seulement ; sans seuil, tout le monde peut entrer", async () => {
    const org = await client.inscrire();
    expect((await creerCercle(client, org, reglementDeTest({ scoreMinimum: 101 }))).status).toBe(400);
    const libre = await json<Cercle>(await creerCercle(client, org, reglementDeTest()));
    expect((await adherer(client, libre, await client.inscrire())).status).toBe(201);
  });
});

describe("catalogue des cercles ouverts (US7)", () => {
  it("seuls les cercles ouverts en attente, filtrés par montant et fréquence, avec ce que mon score permet", async () => {
    const org = await client.inscrire();
    await org.niveau2();
    const montant = 70_000 + Math.floor(Math.random() * 1000);
    const ouvert = await json<Cercle>(
      await creerCercle(client, org, reglementDeTest({ ouvert: true, montant, scoreMinimum: 10 })),
    );
    await creerCercle(client, org, reglementDeTest({ ouvert: false, montant }));
    const moi = await client.inscrire();
    const liste = await json<Record<string, unknown>[]>(
      await client.requete(
        "GET",
        `/cercles/catalogue?montantMin=${montant}&montantMax=${montant}&frequence=hebdomadaire`,
        undefined,
        moi,
      ),
    );
    expect(liste.map((c) => c.id)).toEqual([ouvert.id]);
    expect(liste[0]).toMatchObject({ placesRestantes: 2, premierePlaceAutorisee: 3, scoreSuffisant: false });
    expect(liste[0]).not.toHaveProperty("membres");
    expect(liste[0]).not.toHaveProperty("organisateurId");
    expect(
      await json(
        await client.requete("GET", `/cercles/catalogue?montantMin=${montant}&frequence=mensuelle`, undefined, moi),
      ),
    ).toEqual([]);
  });

  it("filtres validés ; requête signée", async () => {
    const moi = await client.inscrire();
    expect((await client.requete("GET", "/cercles/catalogue?montantMax=abc", undefined, moi)).status).toBe(400);
    expect((await client.requete("GET", "/cercles/catalogue?frequence=annuelle", undefined, moi)).status).toBe(400);
    expect((await client.requete("GET", "/cercles/catalogue")).status).toBe(401);
    expect((await client.requete("GET", "/cercles/catalogue", undefined, moi)).status).toBe(200);
  });
});
