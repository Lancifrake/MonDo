import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { SommeDue } from "./modules/cotisations/sommes-dues.service.js";
import { calculerBareme } from "./score/frais.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let admin: Identite;
let base: BaseDeDonnees;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
  admin = await client.inscrire();
  process.env.MONDO_ADMINISTRATEURS = admin.id;
  base = app.get<BaseDeDonnees>(BASE_DE_DONNEES);
});
afterAll(async () => {
  delete process.env.MONDO_ADMINISTRATEURS;
  await app.close();
});
afterEach(() => vi.unstubAllEnvs());

const json = async <T>(r: Response) => (await r.json()) as T;
const sommes = async (qui: Identite, cercleId?: string) =>
  json<SommeDue[]>(
    await client.requete("GET", cercleId ? `/sommes-dues?cercleId=${cercleId}` : "/sommes-dues", undefined, qui),
  );
const declarer = (id: string, qui?: Identite, reference = "OM-FRAIS-1") =>
  client.requete("POST", `/sommes-dues/${id}/paiement`, { referenceTransaction: reference }, qui);
const confirmer = (id: string, qui?: Identite) =>
  client.requete("POST", `/sommes-dues/${id}/confirmation`, undefined, qui);

/** Cercle de trois à 10 000 FCFA : la place 1 doit 800 à MonDo et 800 au membre de la dernière place. */
async function cercleAvecFrais() {
  const { membres, cercle } = await cercleComplet(client);
  const parPlace = (p: number) => membres.find((m) => m.id === cercle.ordre![p - 1]!.membreId)!;
  const [premier, milieu, dernier] = [parPlace(1), parPlace(2), parPlace(3)];
  const dues = await sommes(premier, cercle.id);
  const exigibles = () =>
    base.requete("UPDATE cotisations.sommes_dues SET exigible_le = now() - interval '1 hour' WHERE cercle_id = $1", [
      cercle.id,
    ]);
  return {
    cercle,
    premier,
    milieu,
    dernier,
    fraisMonDo: dues.find((s) => s.nature === "frais_mondo")!,
    remise: dues.find((s) => s.nature === "remise")!,
    exigibles,
  };
}

describe("barème dans le règlement signé", () => {
  it("un règlement sans barème, ou avec un barème inexact, est refusé", async () => {
    const org = await client.inscrire();
    const { bareme: _b, ...sans } = reglementDeTest();
    expect((await creerCercle(client, org, sans)).status).toBe(400);
    const faux = reglementDeTest({ bareme: [{ place: 1, frais: 10, partMonDo: 5, remiseParPlaceDeFin: 5 }] });
    const r = await creerCercle(client, org, faux);
    expect(r.status).toBe(400);
    expect((await json<{ message: string }>(r)).message).toMatch(/barème/i);
    expect((await creerCercle(client, org, reglementDeTest())).status).toBe(201);
  });

  it("le barème à signer se demande au serveur", async () => {
    const qui = await client.inscrire();
    const r = await client.requete("GET", "/cercles/bareme?nombreMembres=10&montant=50000", undefined, qui);
    expect(await json(r)).toEqual(calculerBareme(10, 50_000));
    expect((await client.requete("GET", "/cercles/bareme?nombreMembres=2&montant=50000", undefined, qui)).status).toBe(
      400,
    );
    expect((await client.requete("GET", "/cercles/bareme?nombreMembres=10&montant=abc", undefined, qui)).status).toBe(
      400,
    );
    expect((await client.requete("GET", "/cercles/bareme?nombreMembres=10&montant=50000")).status).toBe(401);
  });
});

describe("sommes dues créées quand le cercle est complet", () => {
  it("la place 1 doit sa part à MonDo et la remise à la place de fin, aux montants du règlement", async () => {
    const { cercle, premier, milieu, dernier, fraisMonDo, remise } = await cercleAvecFrais();
    expect(fraisMonDo).toMatchObject({ montant: 800, statut: "due", debiteurId: premier.id, tour: 1 });
    expect(fraisMonDo).not.toHaveProperty("creancierId");
    expect(remise).toMatchObject({ montant: 800, statut: "due", debiteurId: premier.id, creancierId: dernier.id });
    // Exigible le jour de la cagnotte, à régler avant la date limite du tour suivant.
    expect(Date.parse(remise.exigibleLe)).toBe(Date.parse(cercle.reglement.datePremierTour));
    expect(Date.parse(remise.dateLimite) - Date.parse(remise.exigibleLe)).toBe(7 * 24 * 3600 * 1000);
    // Chacun ne voit que ce qui le concerne.
    expect((await sommes(dernier, cercle.id)).map((s) => s.id)).toEqual([remise.id]);
    expect(await sommes(milieu, cercle.id)).toEqual([]);
    expect(await sommes(await client.inscrire(), cercle.id)).toEqual([]);
    expect((await sommes(premier)).map((s) => s.id).sort()).toEqual([fraisMonDo.id, remise.id].sort());
    expect((await client.requete("GET", "/sommes-dues")).status).toBe(401);
  });

  it("10 membres : trois places paient, chacune sa part à MonDo et une remise à chacune des trois places de fin", async () => {
    const { cercle } = await cercleComplet(client, reglementDeTest({ nombreMembres: 10, montant: 50_000 }));
    const lignes = await base.requete<{
      nature: string;
      montant: string;
      debiteur_id: string;
      creancier_id: string | null;
    }>("SELECT nature, montant, debiteur_id, creancier_id FROM cotisations.sommes_dues WHERE cercle_id = $1", [
      cercle.id,
    ]);
    expect(lignes).toHaveLength(3 * (1 + 3));
    const total = (nature: string) =>
      lignes.filter((l) => l.nature === nature).reduce((s, l) => s + Number(l.montant), 0);
    expect(total("frais_mondo")).toBe(18_000 + 12_000 + 6_000);
    expect(total("remise")).toBe(3 * (6_000 + 4_000 + 2_000));
    const fin = cercle.ordre!.slice(7).map((p) => p.membreId);
    for (const l of lignes.filter((x) => x.nature === "remise")) expect(fin).toContain(l.creancier_id);
  });
});

describe("suivi d'une somme due, comme une cotisation", () => {
  it("pas de paiement avant la cagnotte ; déclarée par celui qui doit, confirmée par celui qui reçoit", async () => {
    const { premier, milieu, dernier, remise, exigibles } = await cercleAvecFrais();
    expect((await declarer(remise.id, premier)).status).toBe(400);
    await exigibles();
    expect((await declarer(remise.id, dernier)).status).toBe(403);
    expect((await declarer(remise.id, milieu)).status).toBe(403);
    expect((await declarer(remise.id)).status).toBe(401);
    expect((await confirmer(remise.id, dernier)).status).toBe(400);
    const d = await declarer(remise.id, premier);
    expect(d.status).toBe(201);
    expect(await json(d)).toMatchObject({ statut: "declaree", referenceTransaction: "OM-FRAIS-1" });
    // Le silence ne vaut pas confirmation ; celui qui doit ne confirme pas pour l'autre.
    expect((await confirmer(remise.id, premier)).status).toBe(403);
    expect((await confirmer(remise.id, admin)).status).toBe(403);
    expect((await confirmer(remise.id)).status).toBe(401);
    expect(await json(await confirmer(remise.id, dernier))).toMatchObject({ statut: "confirmee" });
    expect((await confirmer(remise.id, dernier)).status).toBe(400);
    expect((await declarer(remise.id, premier, "OM-2")).status).toBe(400);
  });

  it("la part de MonDo est confirmée par un Administrateur, jamais par celui qui la doit", async () => {
    const { premier, dernier, fraisMonDo, exigibles } = await cercleAvecFrais();
    await exigibles();
    await declarer(fraisMonDo.id, premier);
    expect((await confirmer(fraisMonDo.id, dernier)).status).toBe(403);
    vi.stubEnv("MONDO_ADMINISTRATEURS", `${admin.id},${premier.id}`);
    expect((await confirmer(fraisMonDo.id, premier)).status).toBe(403);
    const file = await json<SommeDue[]>(await client.requete("GET", "/administration/sommes-dues", undefined, admin));
    expect(file.map((s) => s.id)).toContain(fraisMonDo.id);
    expect((await client.requete("GET", "/administration/sommes-dues", undefined, dernier)).status).toBe(403);
    expect((await confirmer(fraisMonDo.id, admin)).status).toBe(201);
  });

  it("deux confirmations simultanées : une seule passe ; identifiant inconnu : 404 ; corps strict", async () => {
    const { premier, dernier, remise, exigibles } = await cercleAvecFrais();
    await exigibles();
    expect(
      (await client.requete("POST", `/sommes-dues/${remise.id}/paiement`, { referenceTransaction: "A", x: 1 }, premier))
        .status,
    ).toBe(400);
    await declarer(remise.id, premier);
    // Deux requêtes distinctes (horodatages différents) : l'anti-rejeu ne s'en mêle pas, c'est la base qui tranche.
    const plusTot = new Date(Date.now() - 1000).toISOString();
    const statuts = (
      await Promise.all([
        confirmer(remise.id, dernier),
        client.requete("POST", `/sommes-dues/${remise.id}/confirmation`, undefined, dernier, { horodatage: plusTot }),
      ])
    ).map((r) => r.status);
    expect(statuts.sort()).toEqual([201, 400]);
    expect((await confirmer("00000000-0000-4000-8000-000000000000", dernier)).status).toBe(404);
    expect((await declarer("pas-un-id", premier)).status).toBe(404);
  });

  it("une somme impayée ne touche ni au score ni aux défauts (prototype)", async () => {
    const { premier } = await cercleAvecFrais();
    const s = await json<{ score: number; defauts: number }>(
      await client.requete("GET", `/score/${premier.id}`, undefined, premier),
    );
    expect(s).toMatchObject({ score: 0, defauts: 0 });
  });
});
