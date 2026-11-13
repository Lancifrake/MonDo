import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { messageEchange, type Cercle } from "./modules/cercles/cercles.service.js";
import type { EchangePlace } from "./modules/cercles/echanges.service.js";
import type { SommeDue } from "./modules/cotisations/sommes-dues.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { adherer, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

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

/** Score de 60 (quinze cotisations à temps en cercle ouvert, fictives) : toutes les places sont permises. */
async function bienNote(membre: Identite) {
  for (let i = 0; i < 15; i++) {
    await base.requete(
      "INSERT INTO score.evenements (membre_id, type, cercle_id, date) VALUES ($1, 'cotisation_a_temps', $2, now())",
      [membre.id, randomUUID()],
    );
  }
}

/** Cercle de trois : « ancien » (score 60) a choisi la dernière place, deux nouveaux occupent les places 1 et 2. */
async function cercle(extra: Parameters<typeof reglementDeTest>[0] = {}) {
  const [org, ancien, autre] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
  await bienNote(ancien);
  const reglement = reglementDeTest(extra);
  const cree = await json<Cercle>(await creerCercle(client, org, reglement));
  await adherer(client, cree, ancien, 3);
  await adherer(client, cree, autre);
  const lire = () => client.requete("GET", `/cercles/${cree.id}`, undefined, org).then((r) => json<Cercle>(r));
  const c = await lire();
  const place = (m: Identite, vu: Cercle = c) => vu.ordre!.find((p) => p.membreId === m.id)!.position;
  expect(place(ancien)).toBe(3);
  const premier = [org, autre].find((m) => place(m) === 1)!;
  const deuxieme = [org, autre].find((m) => place(m) === 2)!;
  const message = (demandeur: Identite, cedant: Identite) =>
    messageEchange(c.id, demandeur.id, place(demandeur), cedant.id, place(cedant));
  const proposer = async (demandeur: Identite, cedant: Identite, signataire: Identite = demandeur) =>
    client.requete(
      "POST",
      `/cercles/${c.id}/echanges`,
      { avecMembreId: cedant.id, signature: await signataire.signer(message(demandeur, cedant)) },
      demandeur,
    );
  const accepter = async (
    e: EchangePlace,
    demandeur: Identite,
    cedant: Identite,
    qui: Identite = cedant,
    options = {},
  ) =>
    client.requete(
      "POST",
      `/cercles/${c.id}/echanges/${e.id}/acceptation`,
      { signature: await cedant.signer(message(demandeur, cedant)) },
      qui,
      options,
    );
  const refuser = (e: EchangePlace, qui: Identite) =>
    client.requete("POST", `/cercles/${c.id}/echanges/${e.id}/refus`, undefined, qui);
  const lister = (qui: Identite) =>
    client.requete("GET", `/cercles/${c.id}/echanges`, undefined, qui).then((r) => json<EchangePlace[]>(r));
  return { c, ancien, premier, deuxieme, place, lire, proposer, accepter, refuser, lister };
}

describe("échange de places après complétion (gratuit, choix de David du 11/11)", () => {
  it("signé par les deux : l'ordre, les tours, les cotisations et les frais suivent les nouvelles places", async () => {
    const { c, ancien, premier, deuxieme, place, lire, proposer, accepter, lister } = await cercle();
    const p = await proposer(ancien, premier);
    expect(p.status).toBe(201);
    const echange = await json<EchangePlace>(p);
    expect(echange).toMatchObject({ statut: "propose", demandeurId: ancien.id, cedantId: premier.id });
    expect(Date.parse(echange.expireLe) - Date.parse(echange.proposeLe)).toBe(48 * 3600 * 1000);
    expect((await lister(premier)).map((e) => e.id)).toEqual([echange.id]);
    expect(await lister(deuxieme)).toEqual([]);
    const avantRegistre = (await base.requete("SELECT id FROM registre.empreintes")).length;

    const a = await accepter(echange, ancien, premier);
    expect(a.status).toBe(201);
    expect(await json(a)).toMatchObject({ statut: "signe" });
    const apres = await lire();
    expect(place(ancien, apres)).toBe(1);
    expect(place(premier, apres)).toBe(3);
    expect(place(deuxieme, apres)).toBe(2);
    // Deux inscriptions : l'échange signé par les deux, puis le nouvel ordre de passage.
    expect((await base.requete("SELECT id FROM registre.empreintes")).length).toBe(avantRegistre + 2);

    // Tours et cotisations : « ancien » reçoit au tour 1 et paie aux tours 2 et 3 ; l'autre l'inverse.
    const deAncien = await cotisationsDe(client, c.id, ancien);
    expect(deAncien.filter((x) => x.payeurId === ancien.id).map((x) => x.tour)).toEqual([2, 3]);
    expect(deAncien.filter((x) => x.beneficiaireId === ancien.id).every((x) => x.tour === 1)).toBe(true);
    const dePremier = await cotisationsDe(client, c.id, premier);
    expect(dePremier.filter((x) => x.payeurId === premier.id).map((x) => x.tour)).toEqual([1, 2]);
    expect(dePremier.filter((x) => x.beneficiaireId === premier.id).every((x) => x.tour === 3)).toBe(true);
    // Chaque tour garde deux payeurs distincts du bénéficiaire.
    const lignes = await base.requete<{ tour: number; payeur_id: string; beneficiaire_id: string }>(
      "SELECT tour, payeur_id, beneficiaire_id FROM cotisations.cotisations WHERE cercle_id = $1",
      [c.id],
    );
    expect(lignes).toHaveLength(6);
    for (const l of lignes) expect(l.payeur_id).not.toBe(l.beneficiaire_id);

    // Le nouvel ordre est inscrit au registre : la vérification d'intégrité le reconnaît.
    const registre = await json<{ documents: { objet: string; conforme: boolean }[] }>(
      await client.requete("GET", `/cercles/${c.id}/registre`, undefined, ancien),
    );
    expect(registre.documents).toContainEqual({ objet: "ordre", conforme: true });

    // Frais du modèle A : ils suivent la place, pas la personne.
    const sommes = await json<SommeDue[]>(
      await client.requete("GET", `/sommes-dues?cercleId=${c.id}`, undefined, ancien),
    );
    expect(sommes.map((s) => [s.nature, s.debiteurId, s.creancierId]).sort()).toEqual(
      [
        ["frais_mondo", ancien.id, undefined],
        ["remise", ancien.id, premier.id],
      ].sort(),
    );
  });

  it("jamais plus tôt que ce que permet le score : un nouveau ne prend pas la place 1", async () => {
    const { premier, deuxieme, proposer } = await cercle();
    const r = await proposer(deuxieme, premier);
    expect(r.status).toBe(400);
    expect((await json<{ message: string }>(r)).message).toMatch(/score/);
  });

  it("seul le membre visé accepte ou refuse ; signatures vérifiées ; requêtes signées", async () => {
    const { c, ancien, premier, deuxieme, proposer, accepter, refuser } = await cercle();
    expect((await proposer(ancien, premier, deuxieme)).status).toBe(403);
    expect((await proposer(ancien, ancien)).status).toBe(400);
    const horsCercle = await client.inscrire();
    expect(
      (
        await client.requete(
          "POST",
          `/cercles/${c.id}/echanges`,
          { avecMembreId: horsCercle.id, signature: "x" },
          ancien,
        )
      ).status,
    ).toBe(400);
    expect(
      (await client.requete("POST", `/cercles/${c.id}/echanges`, { avecMembreId: premier.id, signature: "x" })).status,
    ).toBe(401);
    const intrus = await client.inscrire();
    expect(
      (await client.requete("POST", `/cercles/${c.id}/echanges`, { avecMembreId: premier.id, signature: "x" }, intrus))
        .status,
    ).toBe(403);
    const echange = await json<EchangePlace>(await proposer(ancien, premier));
    // Une seule proposition en cours par demandeur.
    expect((await proposer(ancien, premier)).status).toBe(409);
    for (const qui of [ancien, deuxieme, intrus]) {
      expect((await accepter(echange, ancien, premier, qui)).status).toBe(403);
      expect((await refuser(echange, qui)).status).toBe(403);
    }
    const mauvaise = await client.requete(
      "POST",
      `/cercles/${c.id}/echanges/${echange.id}/acceptation`,
      { signature: await ancien.signer("autre chose") },
      premier,
    );
    expect(mauvaise.status).toBe(403);
    expect((await refuser(echange, premier)).status).toBe(201);
    expect((await accepter(echange, ancien, premier)).status).toBe(400);
  });

  it("expire au bout de 48 h sans seconde signature", async () => {
    const { ancien, premier, place, lire, proposer, accepter, lister } = await cercle();
    const echange = await json<EchangePlace>(await proposer(ancien, premier));
    await base.requete("UPDATE cercles.echanges SET expire_le = now() - interval '1 minute' WHERE id = $1", [
      echange.id,
    ]);
    expect((await accepter(echange, ancien, premier)).status).toBe(400);
    expect((await lister(ancien))[0]).toMatchObject({ statut: "expire" });
    expect(place(ancien, await lire())).toBe(3);
    // Une nouvelle proposition redevient possible.
    expect((await proposer(ancien, premier)).status).toBe(201);
  });

  it("suspendu tant qu'un des deux comptes est en récupération", async () => {
    const { ancien, premier, proposer, accepter } = await cercle();
    const echange = await json<EchangePlace>(await proposer(ancien, premier));
    const id = randomUUID();
    await base.requete(
      `INSERT INTO comptes.recuperations (id, compte_id, nouvelle_cle, demandee_le, fin_delai_le, avec_contact, statut)
       VALUES ($1, $2, '{}', now(), now() + interval '48 hours', true, 'en_attente')`,
      [id, ancien.id],
    );
    const r = await accepter(echange, ancien, premier);
    expect(r.status).toBe(409);
    expect((await json<{ message: string }>(r)).message).toMatch(/récupération/);
    await base.requete("UPDATE comptes.recuperations SET statut = 'refusee' WHERE id = $1", [id]);
    expect((await accepter(echange, ancien, premier)).status).toBe(201);
  });

  it("refusé si un des deux tours a commencé (paiement déclaré), et dans un cercle à ordre fixé", async () => {
    const { c, ancien, premier, deuxieme, proposer } = await cercle();
    const due = (await cotisationsDe(client, c.id, deuxieme)).find((x) => x.tour === 1 && x.payeurId === deuxieme.id)!;
    await client.requete("POST", `/cotisations/${due.id}/paiement`, { referenceTransaction: "OM-3" }, deuxieme);
    expect((await proposer(ancien, premier)).status).toBe(400);

    const [org, b, d] = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    const fixe = await json<Cercle>(
      await creerCercle(client, org, reglementDeTest({ ordreFixe: [org.id, b.id, d.id] }), 1),
    );
    await adherer(client, fixe, b, 2);
    await adherer(client, fixe, d, 3);
    const r = await client.requete(
      "POST",
      `/cercles/${fixe.id}/echanges`,
      { avecMembreId: d.id, signature: await org.signer(messageEchange(fixe.id, org.id, 1, d.id, 3)) },
      org,
    );
    expect(r.status).toBe(400);
    expect((await json<{ message: string }>(r)).message).toMatch(/ordre fixé/);
  });

  it("au plus trois propositions par jour et par cercle : pas de SMS en série au même membre", async () => {
    const { ancien, premier, proposer, refuser } = await cercle();
    for (let i = 0; i < 3; i++) {
      const e = await json<EchangePlace>(await proposer(ancien, premier));
      expect((await refuser(e, premier)).status).toBe(201);
    }
    expect((await proposer(ancien, premier)).status).toBe(429);
  });

  it("deux acceptations simultanées : un seul échange", async () => {
    const { c, ancien, premier, place, lire, proposer, accepter } = await cercle();
    const echange = await json<EchangePlace>(await proposer(ancien, premier));
    const plusTot = new Date(Date.now() - 1000).toISOString();
    const statuts = (
      await Promise.all([
        accepter(echange, ancien, premier),
        accepter(echange, ancien, premier, premier, { horodatage: plusTot }),
      ])
    ).map((r) => r.status);
    expect(statuts.sort()).toEqual([201, 400]);
    expect(place(ancien, await lire())).toBe(1);
    const tours = await base.requete("SELECT 1 FROM cotisations.tours WHERE cercle_id = $1 AND beneficiaire_id = $2", [
      c.id,
      ancien.id,
    ]);
    expect(tours).toHaveLength(1);
  });
});
