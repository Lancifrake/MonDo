import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { CotisationsService } from "./modules/cotisations/cotisations.service.js";
import type { SommeDue } from "./modules/cotisations/sommes-dues.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

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

const HEURE_MS = 60 * 60 * 1000;
const json = async <T>(r: Response) => (await r.json()) as T;

/** Cercle de quatre, hebdomadaire. Membres rendus dans l'ordre de passage. */
async function cercle4() {
  const { membres, cercle } = await cercleComplet(client, reglementDeTest({ nombreMembres: 4 }));
  const p = cercle.ordre!.map((place) => membres.find((m) => m.id === place.membreId)!) as [
    Identite,
    Identite,
    Identite,
    Identite,
  ];
  const partir = (qui?: Identite) => client.requete("POST", `/cercles/${cercle.id}/depart`, undefined, qui);
  const due = async (payeur: Identite, tour: number) =>
    (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === tour && c.payeurId === payeur.id)!;
  const declarer = async (payeur: Identite, tour: number) =>
    client.requete(
      "POST",
      `/cotisations/${(await due(payeur, tour)).id}/paiement`,
      { referenceTransaction: "OM-9" },
      payeur,
    );
  const payer = async (payeur: Identite, tour: number, beneficiaire: Identite) => {
    await declarer(payeur, tour);
    await client.requete("POST", `/cotisations/${(await due(payeur, tour)).id}/confirmation`, undefined, beneficiaire);
  };
  const sommes = async (qui: Identite) =>
    json<SommeDue[]>(await client.requete("GET", `/sommes-dues?cercleId=${cercle.id}`, undefined, qui));
  const lire = async (qui: Identite) =>
    json<Cercle>(await client.requete("GET", `/cercles/${cercle.id}`, undefined, qui));
  return { cercle, p, partir, due, declarer, payer, sommes, lire };
}

describe("départ en cours de cycle, avant d'avoir reçu la cagnotte", () => {
  it("son tour est supprimé, ses cotisations futures annulées, ce qu'il a versé lui est remboursé, score −15", async () => {
    const { cercle, p, partir, payer, sommes, lire } = await cercle4();
    const [premier, deuxieme, troisieme, partant] = p;
    await payer(partant, 1, premier);
    const avantRegistre = (await base.requete("SELECT id FROM registre.empreintes")).length;

    const r = await partir(partant);
    expect(r.status).toBe(201);
    expect(await json(r)).toMatchObject({ cercleId: cercle.id, remboursements: 1 });

    const siennes = await cotisationsDe(client, cercle.id, partant);
    // Ce qu'il devait encore (tours 2 et 3) et ce qu'on lui devait (tour 4) : annulé. Ce qu'il a payé : inchangé.
    expect(siennes.filter((c) => c.payeurId === partant.id).map((c) => [c.tour, c.statut])).toEqual([
      [1, "confirmee"],
      [2, "annulee"],
      [3, "annulee"],
    ]);
    expect(siennes.filter((c) => c.beneficiaireId === partant.id).every((c) => c.statut === "annulee")).toBe(true);
    // Les autres tours gardent leurs dates et leurs autres payeurs.
    const deDeuxieme = (await cotisationsDe(client, cercle.id, deuxieme)).filter((c) => c.payeurId === deuxieme.id);
    expect(deDeuxieme.map((c) => [c.tour, c.statut])).toEqual([
      [1, "due"],
      [3, "due"],
      [4, "annulee"],
    ]);

    // Remboursement dû par celui qui a reçu, suivi comme une cotisation.
    const remboursement = (await sommes(partant)).find((s) => s.nature === "remboursement_depart")!;
    expect(remboursement).toMatchObject({
      debiteurId: premier.id,
      creancierId: partant.id,
      montant: 10000,
      statut: "due",
    });
    expect(Date.parse(remboursement.dateLimite) - Date.parse(remboursement.exigibleLe)).toBe(7 * 24 * HEURE_MS);
    const decl = await client.requete(
      "POST",
      `/sommes-dues/${remboursement.id}/paiement`,
      { referenceTransaction: "OM-R" },
      premier,
    );
    expect(decl.status).toBe(201);
    expect(
      (await client.requete("POST", `/sommes-dues/${remboursement.id}/confirmation`, undefined, partant)).status,
    ).toBe(201);

    // Score : +4 pour la cotisation à temps, −15 pour le départ, plancher à 0 ; l'événement est tracé.
    const evenements = await base.requete<{ type: string }>(
      "SELECT type FROM score.evenements WHERE membre_id = $1 ORDER BY id",
      [partant.id],
    );
    expect(evenements.map((e) => e.type)).toEqual(["cotisation_a_temps", "depart"]);
    expect((await base.requete("SELECT id FROM registre.empreintes")).length).toBe(avantRegistre + 1);

    // Les autres le voient parti et sont prévenus ; lui ne voit plus les membres.
    const vu = await lire(troisieme);
    expect(vu.membres).not.toContain(partant.id);
    expect(vu.partis).toEqual([partant.id]);
    expect(await lire(partant)).not.toHaveProperty("membres");
    await app.get(FileSms).vider();
    const numero = (await json<{ numero: string }>(await client.requete("GET", "/comptes/moi", undefined, troisieme)))
      .numero;
    const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages.filter((m) => m.numero === numero);
    expect(sms.at(-1)!.texte).toMatch(/quitté/);
    expect((await partir(partant)).status).toBe(400);
  });

  it("refusé après avoir reçu : dès qu'un paiement vers lui est déclaré", async () => {
    const { p, partir, declarer } = await cercle4();
    const [premier, deuxieme] = p;
    await declarer(deuxieme, 1);
    const r = await partir(premier);
    expect(r.status).toBe(400);
    expect((await json<{ message: string }>(r)).message).toMatch(/cagnotte/);
  });

  it("refusé s'il n'est pas à jour : cotisation échue impayée, ou paiement déclaré en attente", async () => {
    const { cercle, p, partir, declarer, due } = await cercle4();
    const [, , troisieme, quatrieme] = p;
    await declarer(troisieme, 1);
    expect((await partir(troisieme)).status).toBe(400);
    const c = await due(quatrieme, 1);
    await base.requete("UPDATE cotisations.cotisations SET date_limite = now() - interval '1 hour' WHERE id = $1", [
      c.id,
    ]);
    expect((await partir(quatrieme)).status).toBe(400);
    expect((await cotisationsDe(client, cercle.id, quatrieme)).some((x) => x.statut === "annulee")).toBe(false);
  });

  it("réservé à un membre d'un cercle complet ; requête signée", async () => {
    const { cercle, partir } = await cercle4();
    expect((await partir(await client.inscrire())).status).toBe(403);
    expect((await partir()).status).toBe(401);
    const org = await client.inscrire();
    const attente = await json<Cercle>(await creerCercle(client, org, reglementDeTest()));
    expect((await client.requete("POST", `/cercles/${attente.id}/depart`, undefined, org)).status).toBe(400);
    expect((await client.requete("POST", "/cercles/pas-un-id/depart", undefined, org)).status).toBe(404);
    expect(cercle.statut).toBe("complet");
  });

  it("frais du modèle A : les remises qu'on lui devait sont annulées, pas la part de MonDo des autres", async () => {
    const { p, partir, sommes } = await cercle4();
    const [premier, , , dernier] = p;
    expect((await partir(dernier)).status).toBe(201);
    const duPremier = await sommes(premier);
    expect(duPremier.find((s) => s.nature === "remise")).toMatchObject({ statut: "annulee" });
    expect(duPremier.find((s) => s.nature === "frais_mondo")).toMatchObject({ statut: "due" });
  });

  it("après un départ : pas de défaut pour les cotisations annulées, bonus de fin de cycle pour ceux qui restent", async () => {
    const { cercle, p, partir, payer } = await cercle4();
    const [premier, deuxieme, troisieme, partant] = p;
    await partir(partant);
    const restants = [premier, deuxieme, troisieme];
    for (const [i, beneficiaire] of restants.entries()) {
      for (const payeur of restants.filter((m) => m !== beneficiaire)) await payer(payeur, i + 1, beneficiaire);
    }
    const fin = Math.max(...(await cotisationsDe(client, cercle.id, premier)).map((c) => Date.parse(c.finGrace)));
    await app.get(PlanificateurService).examinerEcheances(new Date(fin + 8 * 24 * HEURE_MS));
    const score = async (qui: Identite) =>
      json<{ cyclesTermines: number; defauts: number }>(
        await client.requete("GET", `/score/${qui.id}`, undefined, qui),
      );
    for (const m of restants) expect(await score(m)).toMatchObject({ cyclesTermines: 1, defauts: 0 });
    expect(await score(partant)).toMatchObject({ cyclesTermines: 0, defauts: 0 });
  });

  it("départ interrompu après l'annulation des cotisations : la demande rejouée le termine, un seul −15", async () => {
    const { cercle, p, partir, lire } = await cercle4();
    const [, , troisieme, partant] = p;
    // Panne simulée : le module Cotisations a enregistré le départ, le reste n'a pas eu lieu.
    await app
      .get(CotisationsService)
      .enregistrerDepart(cercle.id, partant.id, new Date(), new Date(Date.now() + 7 * 24 * HEURE_MS));
    expect((await lire(troisieme)).membres).toContain(partant.id);
    expect((await partir(partant)).status).toBe(201);
    expect((await lire(troisieme)).partis).toEqual([partant.id]);
    expect((await partir(partant)).status).toBe(400);
    const evenements = await base.requete("SELECT 1 FROM score.evenements WHERE membre_id = $1 AND type = 'depart'", [
      partant.id,
    ]);
    expect(evenements).toHaveLength(1);
  });

  it("deux demandes de départ simultanées : une seule passe", async () => {
    const { cercle, p } = await cercle4();
    const partant = p[3];
    const plusTot = new Date(Date.now() - 1000).toISOString();
    const statuts = (
      await Promise.all([
        client.requete("POST", `/cercles/${cercle.id}/depart`, undefined, partant),
        client.requete("POST", `/cercles/${cercle.id}/depart`, undefined, partant, { horodatage: plusTot }),
      ])
    ).map((r) => r.status);
    expect(statuts.sort()).toEqual([201, 400]);
    const evenements = await base.requete("SELECT 1 FROM score.evenements WHERE membre_id = $1 AND type = 'depart'", [
      partant.id,
    ]);
    expect(evenements).toHaveLength(1);
  });
});
