import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { Cotisation } from "./modules/cotisations/cotisations.service.js";
import type { Litige } from "./modules/litiges/litiges.service.js";
import { ComptesService } from "./modules/comptes/comptes.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let admin: Identite;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
  admin = await client.inscrire();
  // Compte administrateur fictif de test, lu à chaque requête.
  process.env.MONDO_ADMINISTRATEURS = admin.id;
});
afterAll(async () => {
  delete process.env.MONDO_ADMINISTRATEURS;
  await app.close();
});

const HEURE_MS = 60 * 60 * 1000;
const json = async <T>(r: Response) => (await r.json()) as T;

/** Premier tour d'un cercle de trois : le payeur a déclaré son paiement, le bénéficiaire ne confirme pas. */
async function paiementNonConfirme() {
  const { membres, cercle } = await cercleComplet(client, reglementDeTest());
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const [payeur, autre] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
  const cotisation = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1)!;
  await client.requete("POST", `/cotisations/${cotisation.id}/paiement`, { referenceTransaction: "OM-123" }, payeur);
  const vieillir = (heures: number) =>
    app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete("UPDATE cotisations.cotisations SET declaree_le = now() - $2::interval WHERE id = $1", [
        cotisation.id,
        `${heures} hours`,
      ]);
  const ouvrir = (qui: Identite, motif = "Paiement envoyé, pas de confirmation") =>
    client.requete("POST", "/litiges", { cotisationId: cotisation.id, motif }, qui);
  const trancher = (litigeId: string, decision: "paiement_valide" | "paiement_refuse", qui: Identite = admin) =>
    client.requete("POST", `/litiges/${litigeId}/decision`, { decision, motif: "Relevé Mobile Money vérifié" }, qui);
  const etat = async () =>
    (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.id === cotisation.id) as Cotisation;
  const score = async (qui: Identite) =>
    json<{ score: number; defauts: number }>(await client.requete("GET", `/score/${qui.id}`, undefined, qui));
  return { cercle, beneficiaire, payeur, autre, cotisation, vieillir, ouvrir, trancher, etat, score };
}

describe("ouverture d'un litige", () => {
  it("le payeur : seulement après 48 h sans confirmation", async () => {
    const { payeur, vieillir, ouvrir } = await paiementNonConfirme();
    expect((await ouvrir(payeur)).status).toBe(400);
    await vieillir(49);
    const r = await ouvrir(payeur);
    expect(r.status).toBe(201);
    expect(await json<Litige>(r)).toMatchObject({ ouvertPar: "payeur", statut: "ouvert" });
  });

  it("le bénéficiaire qui dit « je n'ai rien reçu » : tout de suite", async () => {
    const { beneficiaire, ouvrir } = await paiementNonConfirme();
    const r = await ouvrir(beneficiaire, "Rien reçu sur mon compte");
    expect(r.status).toBe(201);
    expect(await json<Litige>(r)).toMatchObject({ ouvertPar: "beneficiaire", motif: "Rien reçu sur mon compte" });
  });

  it("refusée à un membre qui n'est pas partie, sur une cotisation non déclarée, et en double", async () => {
    const { cercle, beneficiaire, autre, ouvrir } = await paiementNonConfirme();
    expect((await ouvrir(autre)).status).toBe(403);
    const nonDeclaree = (await cotisationsDe(client, cercle.id, autre)).find((c) => c.tour === 1)!;
    const r = await client.requete("POST", "/litiges", { cotisationId: nonDeclaree.id, motif: "x" }, beneficiaire);
    expect(r.status).toBe(400);
    expect((await ouvrir(beneficiaire)).status).toBe(201);
    expect((await ouvrir(beneficiaire)).status).toBe(409);
  });

  it("automatique à la fin de grâce, une seule fois, et jamais un défaut", async () => {
    const { payeur, cotisation, score } = await paiementNonConfirme();
    const planificateur = app.get(PlanificateurService);
    const apres = Date.parse(cotisation.finGrace) + HEURE_MS;
    await planificateur.examinerEcheances(new Date(apres));
    await planificateur.examinerEcheances(new Date(apres + HEURE_MS));
    const ouverts = await json<Litige[]>(await client.requete("GET", "/litiges", undefined, admin));
    const lies = ouverts.filter((l) => l.cotisationId === cotisation.id);
    expect(lies).toHaveLength(1);
    expect(lies[0]).toMatchObject({ ouvertPar: "automatique", statut: "ouvert" });
    expect((await score(payeur)).defauts).toBe(0);
  });
});

describe("décision de l'administrateur", () => {
  it("paiement validé : cotisation confirmée, à temps si déclarée avant la date limite ; le bénéficiaire ne perd rien", async () => {
    const { beneficiaire, payeur, ouvrir, trancher, etat, score } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    const avant = await score(beneficiaire);
    const r = await trancher(litige.id, "paiement_valide");
    expect(r.status).toBe(201);
    expect(await json<Litige>(r)).toMatchObject({
      statut: "tranche",
      decision: "paiement_valide",
      tranchePar: admin.id,
    });
    expect((await etat()).statut).toBe("confirmee");
    expect((await score(payeur)).score).toBe(4);
    expect(await score(beneficiaire)).toEqual(avant);
    const vu = await json<Litige>(await client.requete("GET", `/litiges/${litige.id}`, undefined, payeur));
    expect(vu.decision).toBe("paiement_valide");
  });

  it("paiement refusé : la cotisation redevient due, puis défaut au passage suivant si la grâce est passée", async () => {
    const { beneficiaire, payeur, cotisation, ouvrir, trancher, etat, score } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    expect((await trancher(litige.id, "paiement_refuse")).status).toBe(201);
    const c = await etat();
    expect(c.statut).toBe("due");
    expect(c.referenceTransaction).toBeUndefined();
    await app.get(PlanificateurService).examinerEcheances(new Date(Date.parse(cotisation.finGrace) + HEURE_MS));
    expect((await score(payeur)).defauts).toBe(1);
  });

  it("réservée à l'administrateur, qui ne tranche pas un litige où il est partie ; une seule décision", async () => {
    const { beneficiaire, payeur, ouvrir, trancher } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    expect((await trancher(litige.id, "paiement_valide", payeur)).status).toBe(403);
    expect((await client.requete("GET", "/litiges", undefined, payeur)).status).toBe(403);

    process.env.MONDO_ADMINISTRATEURS = `${admin.id},${beneficiaire.id}`;
    expect((await trancher(litige.id, "paiement_valide", beneficiaire)).status).toBe(403);
    process.env.MONDO_ADMINISTRATEURS = admin.id;

    expect((await trancher(litige.id, "paiement_refuse")).status).toBe(201);
    expect((await trancher(litige.id, "paiement_valide")).status).toBe(400);
  });

  it("un membre extérieur ne lit pas le litige", async () => {
    const { beneficiaire, autre, ouvrir } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    expect((await client.requete("GET", `/litiges/${litige.id}`, undefined, autre)).status).toBe(403);
  });

  it("le bénéficiaire finit par confirmer lui-même : le litige est clos sans décision", async () => {
    const { beneficiaire, payeur, cotisation, ouvrir } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    await client.requete("POST", `/cotisations/${cotisation.id}/confirmation`, undefined, beneficiaire);
    const vu = await json<Litige>(await client.requete("GET", `/litiges/${litige.id}`, undefined, payeur));
    expect(vu).toMatchObject({ statut: "clos", decision: "confirme_par_beneficiaire" });
  });
});

/** SMS de litige reçus par un membre (hors code de connexion), une fois la file d'envoi vidée. */
async function smsDe(qui: Identite): Promise<string[]> {
  await app.get(FileSms).vider();
  const numero = (await app.get(ComptesService).chercher(qui.id))!.numero;
  return app
    .get<ConnecteurSmsSimule>(CONNECTEUR_SMS)
    .messages.filter((m) => m.numero === numero && /litige/i.test(m.texte))
    .map((m) => m.texte);
}

describe("les parties sont prévenues par SMS", () => {
  it("ouverture : payeur et bénéficiaire reçoivent le numéro de suivi, l'autre membre rien", async () => {
    const { beneficiaire, payeur, autre, ouvrir } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    const suivi = litige.id.slice(0, 8);
    for (const qui of [payeur, beneficiaire]) {
      const recus = await smsDe(qui);
      expect(recus).toHaveLength(1);
      expect(recus[0]).toContain(suivi);
      expect(recus[0]).toContain("tour 1");
    }
    expect(await smsDe(autre)).toEqual([]);
  });

  it("ouverture automatique rejouée : un seul SMS par partie", async () => {
    const { beneficiaire, payeur, cotisation } = await paiementNonConfirme();
    const planificateur = app.get(PlanificateurService);
    const apres = Date.parse(cotisation.finGrace) + HEURE_MS;
    await planificateur.examinerEcheances(new Date(apres));
    await planificateur.examinerEcheances(new Date(apres + HEURE_MS));
    expect(await smsDe(payeur)).toHaveLength(1);
    expect(await smsDe(beneficiaire)).toHaveLength(1);
  });

  it("décision : chaque partie apprend l'issue ; un refus dit au payeur de régler vite", async () => {
    const { beneficiaire, payeur, ouvrir, trancher } = await paiementNonConfirme();
    const litige = await json<Litige>(await ouvrir(beneficiaire));
    await trancher(litige.id, "paiement_refuse");
    const auPayeur = await smsDe(payeur);
    expect(auPayeur).toHaveLength(2);
    expect(auPayeur[1]).toMatch(/refus/);
    expect(auPayeur[1]).toMatch(/défaut/);
    expect((await smsDe(beneficiaire))[1]).toMatch(/refus/);
  });

  it("paiement validé et clôture par le bénéficiaire : SMS aux deux parties", async () => {
    const a = await paiementNonConfirme();
    const l1 = await json<Litige>(await a.ouvrir(a.beneficiaire));
    await a.trancher(l1.id, "paiement_valide");
    expect((await smsDe(a.payeur))[1]).toMatch(/validé/);

    const b = await paiementNonConfirme();
    await b.ouvrir(b.beneficiaire);
    await client.requete("POST", `/cotisations/${b.cotisation.id}/confirmation`, undefined, b.beneficiaire);
    expect((await smsDe(b.payeur))[1]).toMatch(/clos/);
    expect(await smsDe(b.beneficiaire)).toHaveLength(2);
  });
});
