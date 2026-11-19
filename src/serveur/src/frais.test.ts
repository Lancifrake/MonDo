import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { SommeDue, SommeDuePourAdministrateur } from "./modules/cotisations/sommes-dues.service.js";
import { calculerBareme } from "./score/frais.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";

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
  const { membres, cercle } = await cercleComplet(client, undefined, { fraisRegles: false });
  const parPlace = (p: number) => membres.find((m) => m.id === cercle.ordre![p - 1]!.membreId)!;
  const [premier, milieu, dernier] = [parPlace(1), parPlace(2), parPlace(3)];
  const dues = await sommes(premier, cercle.id);
  return {
    cercle,
    premier,
    milieu,
    dernier,
    fraisMonDo: dues.find((s) => s.nature === "frais_mondo")!,
    remise: dues.find((s) => s.nature === "remise")!,
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
    // Payés avant la cagnotte : exigibles dès que le cercle est complet, à régler avant la date limite de son tour.
    expect(Date.parse(remise.exigibleLe)).toBeLessThanOrEqual(Date.now());
    expect(Date.parse(remise.dateLimite)).toBe(Date.parse(cercle.reglement.datePremierTour));
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
  it("déclarée par celui qui doit, confirmée par celui qui reçoit", async () => {
    const { premier, milieu, dernier, remise } = await cercleAvecFrais();
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
    const { premier, dernier, fraisMonDo } = await cercleAvecFrais();
    await declarer(fraisMonDo.id, premier);
    expect((await confirmer(fraisMonDo.id, dernier)).status).toBe(403);
    vi.stubEnv("MONDO_ADMINISTRATEURS", `${admin.id},${premier.id}`);
    expect((await confirmer(fraisMonDo.id, premier)).status).toBe(403);
    const file = await json<SommeDuePourAdministrateur[]>(
      await client.requete("GET", "/administration/sommes-dues", undefined, admin),
    );
    expect(file.map((s) => s.id)).toContain(fraisMonDo.id);
    // L'Administrateur voit qui a payé et pour quel cercle, pour rapprocher la référence du compte marchand.
    const ligne = file.find((s) => s.id === fraisMonDo.id)!;
    const moi = await json<{ nom: string; numero: string }>(
      await client.requete("GET", "/comptes/moi", undefined, premier),
    );
    expect(ligne.debiteur).toEqual({ nom: moi.nom, numero: moi.numero });
    expect(ligne.cercle).toMatchObject({
      organisateur: expect.stringMatching(/^Membre /),
      montant: 10_000,
      nombreMembres: 3,
    });
    expect((await client.requete("GET", "/administration/sommes-dues", undefined, dernier)).status).toBe(403);
    expect((await confirmer(fraisMonDo.id, admin)).status).toBe(201);
  });

  it("deux confirmations simultanées : une seule passe ; identifiant inconnu : 404 ; corps strict", async () => {
    const { premier, dernier, remise } = await cercleAvecFrais();
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

describe("frais de place payés avant la cagnotte (décision du 19/11)", () => {
  it("les frais d'un tour deviennent exigibles à la fin du tour précédent, pas avant", async () => {
    const { cercle, membres } = await cercleComplet(client, reglementDeTest({ nombreMembres: 10, montant: 50_000 }), {
      fraisRegles: false,
    });
    const tours = await base.requete<{ numero: number; date_limite: Date }>(
      "SELECT numero, date_limite FROM cotisations.tours WHERE cercle_id = $1 ORDER BY numero",
      [cercle.id],
    );
    const lignes = await base.requete<{ tour: number; exigible_le: Date; date_limite: Date }>(
      "SELECT tour, exigible_le, date_limite FROM cotisations.sommes_dues WHERE cercle_id = $1 AND nature = 'frais_mondo' ORDER BY tour",
      [cercle.id],
    );
    expect(lignes.map((l) => l.tour)).toEqual([1, 2, 3]);
    // Place 1 : dès que le cercle est complet. Places suivantes : à la date limite du tour d'avant.
    expect(new Date(lignes[0]!.exigible_le).getTime()).toBeLessThanOrEqual(Date.now());
    expect(new Date(lignes[1]!.exigible_le).getTime()).toBe(new Date(tours[0]!.date_limite).getTime());
    expect(new Date(lignes[2]!.exigible_le).getTime()).toBe(new Date(tours[1]!.date_limite).getTime());
    // La place 2 ne peut pas régler ses frais avant : la somme n'est pas encore exigible.
    const placeDeux = membres.find((m) => m.id === cercle.ordre![1]!.membreId)!;
    const sienne = (await sommes(placeDeux, cercle.id)).find((x) => x.nature === "frais_mondo")!;
    const trop = await declarer(sienne.id, placeDeux);
    expect(trop.status).toBe(400);
    expect((await json<{ message: string }>(trop)).message).toMatch(/pas encore exigible/);
  });

  it("les cotisations vers un bénéficiaire restent fermées tant qu'il n'a pas réglé ses frais de place", async () => {
    const { cercle, premier, milieu, fraisMonDo, remise } = await cercleAvecFrais();
    const due = async () => (await cotisationsDe(client, cercle.id, milieu)).find((c) => c.tour === 1)!;
    const declarerCotisation = async () =>
      client.requete("POST", `/cotisations/${(await due()).id}/paiement`, { referenceTransaction: "OM-G" }, milieu);
    const refus = await declarerCotisation();
    expect(refus.status).toBe(400);
    expect((await json<{ message: string }>(refus)).message).toMatch(/frais de place/);
    // Remise et part de MonDo déclarées : la part de MonDo doit aussi être confirmée avant d'ouvrir le tour.
    await declarer(remise.id, premier);
    await declarer(fraisMonDo.id, premier, "OM-FRAIS-2");
    expect((await declarerCotisation()).status).toBe(400);
    expect((await confirmer(fraisMonDo.id, admin)).status).toBe(201);
    expect((await declarerCotisation()).status).toBe(201);
  });

  it("un tour fermé ne fait de défaut pour personne, et les payeurs repartent de zéro quand il s'ouvre", async () => {
    const { cercle, premier, milieu, fraisMonDo, remise } = await cercleAvecFrais();
    const planificateur = app.get(PlanificateurService);
    // Le bénéficiaire a déclaré ses frais, l'Administrateur n'a pas encore confirmé, et les dates du tour sont passées :
    // les payeurs n'ont pas pu payer, et le retard est celui de MonDo, donc personne ne perd rien.
    await declarer(remise.id, premier);
    await declarer(fraisMonDo.id, premier, "OM-FRAIS-3");
    await base.requete(
      `UPDATE cotisations.cotisations SET date_limite = now() - interval '5 days', fin_grace = now() - interval '3 days'
       WHERE cercle_id = $1 AND tour = 1`,
      [cercle.id],
    );
    await planificateur.examinerEcheances();
    const score = async (qui: Identite) =>
      json<{ defauts: number }>(await client.requete("GET", `/score/${qui.id}`, undefined, qui));
    expect((await score(milieu)).defauts).toBe(0);
    expect((await score(premier)).defauts).toBe(0);
    // Le tour s'ouvre : les cotisations encore dues reçoivent une nouvelle échéance, avec leur délai de grâce.
    expect((await confirmer(fraisMonDo.id, admin)).status).toBe(201);
    const ouverte = (await cotisationsDe(client, cercle.id, milieu)).find(
      (c) => c.tour === 1 && c.payeurId === milieu.id,
    )!;
    expect(Date.parse(ouverte.dateLimite)).toBeGreaterThanOrEqual(Date.now() - 1000);
    expect(Date.parse(ouverte.finGrace)).toBeGreaterThan(Date.parse(ouverte.dateLimite));
    await planificateur.examinerEcheances();
    expect((await score(milieu)).defauts).toBe(0);
  });

  it("frais toujours pas payés à la fin de grâce de son tour : le bénéficiaire perd sa place, compté comme un défaut", async () => {
    const { cercle, premier, milieu, fraisMonDo, remise } = await cercleAvecFrais();
    await base.requete(
      `UPDATE cotisations.cotisations SET date_limite = now() - interval '5 days', fin_grace = now() - interval '3 days'
       WHERE cercle_id = $1 AND tour = 1`,
      [cercle.id],
    );
    await app.get(PlanificateurService).examinerEcheances();
    const vu = await json<{ partis?: string[] }>(
      await client.requete("GET", `/cercles/${cercle.id}`, undefined, milieu),
    );
    expect(vu.partis).toEqual([premier.id]);
    // Son tour est supprimé, ses frais annulés ; c'est un défaut sur son score, pas un simple départ.
    const versLui = (await cotisationsDe(client, cercle.id, milieu)).filter((c) => c.beneficiaireId === premier.id);
    expect(versLui.every((c) => c.statut === "annulee")).toBe(true);
    const siennes = await sommes(premier, cercle.id);
    expect(siennes.find((s) => s.id === fraisMonDo.id)).toMatchObject({ statut: "annulee" });
    expect(siennes.find((s) => s.id === remise.id)).toMatchObject({ statut: "annulee" });
    const types = await base.requete<{ type: string }>("SELECT type FROM score.evenements WHERE membre_id = $1", [
      premier.id,
    ]);
    expect(types.map((t) => t.type)).toEqual(["defaut"]);
    // Rejouer l'examen ne change rien.
    await app.get(PlanificateurService).examinerEcheances();
    expect((await base.requete("SELECT type FROM score.evenements WHERE membre_id = $1", [premier.id])).length).toBe(1);
  });
});
