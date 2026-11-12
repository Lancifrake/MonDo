import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import type { NestExpressApplication } from "@nestjs/platform-express";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { configurerApplication } from "./application.js";
import { messagePiecesRecuperation, messageRecuperation } from "./authentification/messages.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { BlocagesService } from "./modules/comptes/blocages.service.js";
import { RecuperationService } from "./modules/comptes/recuperation.service.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe } from "./testing/cercles.js";
import { avecContactConsentant, dossierIdentite } from "./testing/identite.js";
import { nouveauTelephone } from "./testing/telephone.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let admin: Identite;
let base: BaseDeDonnees;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication({
    bodyParser: false,
  });
  configurerApplication(app as NestExpressApplication);
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

const HEURE_MS = 60 * 60 * 1000;
const json = async <T>(r: Response) => (await r.json()) as T;
const moi = (qui: Identite) => client.requete("GET", "/comptes/moi", undefined, qui);
const numeroDe = async (qui: Identite) => (await json<{ numero: string }>(await moi(qui))).numero;
const smsVers = (numero: string) =>
  app
    .get<ConnecteurSmsSimule>(CONNECTEUR_SMS)
    .messages.filter((m) => m.numero === numero && !/votre code est/.test(m.texte));

interface Demande {
  id: string;
  finDelaiLe: string;
  avecContact: boolean;
  piecesRequises: boolean;
  statut: string;
}

/** Membre avec, au choix, un code secret et un contact de confiance qui a donné son accord. */
async function membre(options: { codeSecret?: string; contact?: boolean } = {}) {
  const titulaire = await client.inscrire();
  const numero = await numeroDe(titulaire);
  if (options.codeSecret) {
    const r = await client.requete("POST", "/comptes/moi/code-secret", { code: options.codeSecret }, titulaire);
    expect(r.status).toBe(201);
  }
  const contact = options.contact ? await avecContactConsentant(app, client, titulaire) : undefined;
  return { titulaire, numero, contact };
}

/** Le nouveau téléphone : nouvelle clé, code SMS reçu sur le numéro, code secret saisi. */
async function demander(numero: string, extra: Record<string, unknown> = {}, id?: string) {
  const tel = await nouveauTelephone();
  const corps = {
    numero,
    clePublique: tel.clePublique,
    preuve: await tel.signer(messageRecuperation({ numero, clePublique: tel.clePublique })),
    codeOtp: await client.codeOtp(numero),
    ...extra,
  };
  const r = await client.requete("POST", "/comptes/recuperation", corps);
  const demande = r.status === 201 ? await json<Demande>(r.clone()) : undefined;
  return { r, demande, nouveau: { id: id ?? "", signer: tel.signer } as Identite };
}
/** Laisse passer une minute fictive entre deux codes SMS du même numéro. */
const reposOtp = (numero: string) =>
  base.requete("UPDATE comptes.codes_otp SET cree_le = cree_le - interval '2 minutes' WHERE numero = $1", [numero]);
const finaliser = (dans: number) => app.get(RecuperationService).finaliser(new Date(Date.now() + dans * HEURE_MS));

describe("code secret", () => {
  it("se définit par une requête signée, jamais gardé en clair ; format contrôlé", async () => {
    const { titulaire } = await membre();
    expect((await client.requete("POST", "/comptes/moi/code-secret", { code: "12" }, titulaire)).status).toBe(400);
    expect((await client.requete("POST", "/comptes/moi/code-secret", { code: "482615" })).status).toBe(401);
    expect((await client.requete("POST", "/comptes/moi/code-secret", { code: "482615" }, titulaire)).status).toBe(201);
    const lignes = await base.requete("SELECT * FROM comptes.codes_secrets WHERE compte_id = $1", [titulaire.id]);
    expect(lignes).toHaveLength(1);
    expect(JSON.stringify(lignes)).not.toContain("482615");
  });
});

describe("récupération avec contact de confiance : 48 h", () => {
  it("demande acceptée, titulaire et contact prévenus ; la nouvelle clé ne vaut qu'après le délai", async () => {
    const { titulaire, numero, contact } = await membre({ codeSecret: "482615", contact: true });
    const { r, demande, nouveau } = await demander(numero, { codeSecret: "482615" }, titulaire.id);
    expect(r.status).toBe(201);
    expect(demande).toMatchObject({ avecContact: true, piecesRequises: false, statut: "en_attente" });
    expect(Date.parse(demande!.finDelaiLe) - Date.now()).toBeGreaterThan(47 * HEURE_MS);
    expect(Date.parse(demande!.finDelaiLe) - Date.now()).toBeLessThanOrEqual(48 * HEURE_MS);
    expect(JSON.stringify(demande)).not.toContain(titulaire.id);
    await app.get(FileSms).vider();
    expect(smsVers(numero).at(-1)!.texte).toMatch(/récupération/i);
    expect(smsVers(contact!).at(-1)!.texte).toMatch(/récupération/i);
    expect(await app.get(RecuperationService).enRecuperation(titulaire.id)).toBe(true);
    expect(await json(await client.requete("GET", "/comptes/moi/recuperation", undefined, titulaire))).toMatchObject({
      statut: "en_attente",
    });

    await finaliser(47);
    expect((await moi(nouveau)).status).toBe(401);
    expect((await moi(titulaire)).status).toBe(200);

    const avant = (await base.requete("SELECT id FROM registre.empreintes")).length;
    await finaliser(49);
    expect((await moi(nouveau)).status).toBe(200);
    expect((await moi(titulaire)).status).toBe(401);
    expect((await base.requete("SELECT id FROM registre.empreintes")).length).toBe(avant + 1);
    expect(await app.get(RecuperationService).enRecuperation(titulaire.id)).toBe(false);
    // Rejouable : un second passage ne change rien.
    await finaliser(60);
    expect((await moi(nouveau)).status).toBe(200);
  });

  it("refuse un mauvais code SMS, un numéro inconnu, une preuve de clé fausse, avec la même réponse", async () => {
    const { numero } = await membre({ codeSecret: "482615", contact: true });
    const mauvais = await demander(numero, { codeSecret: "482615", codeOtp: "000000" });
    const inconnu = await demander("+237611110000", { codeSecret: "482615" });
    await reposOtp(numero);
    const faux = await demander(numero, { codeSecret: "482615", preuve: "AAAA" });
    for (const { r } of [mauvais, inconnu, faux]) expect(r.status).toBe(403);
    expect((await json<{ message: string }>(mauvais.r)).message).toBe(
      (await json<{ message: string }>(inconnu.r)).message,
    );
  });

  it("une seule demande à la fois ; corps strict", async () => {
    const { numero } = await membre({ codeSecret: "482615", contact: true });
    expect((await demander(numero, { codeSecret: "482615" })).r.status).toBe(201);
    await reposOtp(numero);
    expect((await demander(numero, { codeSecret: "482615" })).r.status).toBe(409);
    expect((await client.requete("POST", "/comptes/recuperation", { numero, intrus: true })).status).toBe(400);
  });
});

describe("récupération sans contact : 72 h, carte d'identité et selfie", () => {
  it("sans pièces validées par un Administrateur, rien ne se passe ; avec, la clé change après 72 h", async () => {
    const { titulaire, numero } = await membre({ codeSecret: "482615" });
    const { demande, nouveau } = await demander(numero, { codeSecret: "482615" }, titulaire.id);
    expect(demande).toMatchObject({ avecContact: false, piecesRequises: true });
    expect(Date.parse(demande!.finDelaiLe) - Date.now()).toBeGreaterThan(71 * HEURE_MS);

    await finaliser(73);
    expect((await moi(nouveau)).status).toBe(401);

    const deposer = async (signataire: Identite) => {
      const horodatage = new Date().toISOString();
      return client.requete("POST", `/comptes/recuperation/${demande!.id}/pieces`, {
        ...dossierIdentite(),
        horodatage,
        preuve: await signataire.signer(messagePiecesRecuperation(demande!.id, horodatage)),
      });
    };
    // Seul le téléphone qui a fait la demande dépose les pièces.
    expect((await deposer(await client.inscrire())).status).toBe(403);
    const horodatage = new Date().toISOString();
    const corps = {
      ...dossierIdentite(),
      horodatage,
      preuve: await nouveau.signer(messagePiecesRecuperation(demande!.id, horodatage)),
    };
    const chemin = `/comptes/recuperation/${demande!.id}/pieces`;
    expect((await client.requete("POST", chemin, corps)).status).toBe(201);
    // Le même envoi intercepté et rejoué est refusé, même si le premier dossier a été écarté entre-temps.
    await base.requete("UPDATE comptes.verifications_identite SET statut = 'refusee' WHERE recuperation_id = $1", [
      demande!.id,
    ]);
    expect((await client.requete("POST", chemin, corps)).status).toBe(403);
    await base.requete("UPDATE comptes.verifications_identite SET statut = 'en_attente' WHERE recuperation_id = $1", [
      demande!.id,
    ]);
    await finaliser(73);
    expect((await moi(nouveau)).status).toBe(401);

    const file = await json<{ id: string; compteId: string; motif: string }[]>(
      await client.requete("GET", "/administration/identites", undefined, admin),
    );
    const dossier = file.find((d) => d.compteId === titulaire.id)!;
    expect(dossier.motif).toBe("recuperation");
    const decision = { decision: "validee", motif: "Carte et visage conformes" };
    expect(
      (await client.requete("POST", `/administration/identites/${dossier.id}/decision`, decision, admin)).status,
    ).toBe(201);
    // Aucune image ne reste après une vérification de récupération, et le niveau ne change pas.
    const restantes = await base.requete(
      "SELECT 1 FROM comptes.pieces_identite WHERE verification_id = $1 AND supprimee_le IS NULL",
      [dossier.id],
    );
    expect(restantes).toHaveLength(0);
    await finaliser(73);
    expect((await moi(nouveau)).status).toBe(200);
    expect(await json(await moi(nouveau))).toMatchObject({ niveau: 1 });
  });

  it("sans code secret défini, même avec un contact : chemin le plus strict", async () => {
    const { numero } = await membre({ contact: true });
    const { demande } = await demander(numero);
    expect(demande).toMatchObject({ avecContact: false, piecesRequises: true });
  });

  it("pièces refusées : demande refusée ; jamais déposées : demande expirée après 7 jours de plus", async () => {
    const { titulaire, numero } = await membre({ codeSecret: "482615" });
    const { nouveau } = await demander(numero, { codeSecret: "482615" }, titulaire.id);
    await finaliser(72 + 7 * 24 + 1);
    expect((await moi(nouveau)).status).toBe(401);
    expect((await client.requete("GET", "/comptes/moi/recuperation", undefined, titulaire)).status).toBe(404);
    expect(await app.get(RecuperationService).enRecuperation(titulaire.id)).toBe(false);
  });
});

describe("opposition du titulaire et compte bloqué", () => {
  async function opposee() {
    const { titulaire, numero } = await membre({ codeSecret: "482615", contact: true });
    const { demande, nouveau } = await demander(numero, { codeSecret: "482615" }, titulaire.id);
    const r = await client.requete("POST", "/comptes/moi/recuperation/opposition", undefined, titulaire);
    return { titulaire, nouveau, demande: demande!, r };
  }
  const trancher = (id: string, decision: string, qui: Identite = admin) =>
    client.requete(
      "POST",
      `/administration/recuperations/${id}/decision`,
      { decision, motif: "Identité vérifiée de vive voix" },
      qui,
    );

  it("le titulaire s'oppose : compte bloqué, dossier chez l'Administrateur, le délai ne joue plus", async () => {
    const { titulaire, nouveau, demande, r } = await opposee();
    expect(r.status).toBe(201);
    expect((await moi(titulaire)).status).toBe(423);
    await finaliser(49);
    expect((await moi(nouveau)).status).toBe(401);
    const file = await json<{ id: string }[]>(
      await client.requete("GET", "/administration/recuperations", undefined, admin),
    );
    expect(file.map((d) => d.id)).toContain(demande.id);
  });

  it("personne d'autre ne s'oppose à ma place ; la file et la décision sont réservées à l'Administrateur", async () => {
    const { titulaire, demande } = await opposee();
    const tiers = await client.inscrire();
    expect((await client.requete("POST", "/comptes/moi/recuperation/opposition", undefined, tiers)).status).toBe(404);
    expect((await client.requete("POST", "/comptes/moi/recuperation/opposition")).status).toBe(401);
    expect((await client.requete("GET", "/administration/recuperations", undefined, tiers)).status).toBe(403);
    expect((await trancher(demande.id, "titulaire_confirme", tiers)).status).toBe(403);
    expect((await trancher(demande.id, "nimporte")).status).toBe(400);
    expect((await moi(titulaire)).status).toBe(423);
  });

  it("l'Administrateur confirme le titulaire : compte débloqué, ancienne clé gardée", async () => {
    const { titulaire, nouveau, demande } = await opposee();
    expect((await trancher(demande.id, "titulaire_confirme")).status).toBe(201);
    expect((await moi(titulaire)).status).toBe(200);
    expect((await moi(nouveau)).status).toBe(401);
    expect((await trancher(demande.id, "recuperation_acceptee")).status).toBe(400);
  });

  it("l'Administrateur accepte la récupération : compte débloqué, nouvelle clé", async () => {
    const { titulaire, nouveau, demande } = await opposee();
    expect((await trancher(demande.id, "recuperation_acceptee")).status).toBe(201);
    expect((await moi(nouveau)).status).toBe(200);
    expect((await moi(titulaire)).status).toBe(401);
  });

  it("un Administrateur ne tranche pas la récupération de son propre compte", async () => {
    const numero = await numeroDe(admin);
    await client.requete("POST", "/comptes/moi/code-secret", { code: "482615" }, admin);
    const { demande } = await demander(numero, { codeSecret: "482615" });
    await base.requete("UPDATE comptes.recuperations SET statut = 'opposee' WHERE id = $1", [demande!.id]);
    expect((await trancher(demande!.id, "recuperation_acceptee")).status).toBe(403);
    await base.requete("UPDATE comptes.recuperations SET statut = 'refusee' WHERE id = $1", [demande!.id]);
  });
});

describe("trop d'essais ratés du code secret : blocage temporaire", () => {
  it("cinq codes secrets faux : compte bloqué 24 h, levé par le temps", async () => {
    const { titulaire, numero } = await membre({ codeSecret: "482615", contact: true });
    for (let i = 0; i < 5; i++) {
      expect((await demander(numero, { codeSecret: "000000" })).r.status).toBe(403);
      await reposOtp(numero);
      await base.requete("UPDATE comptes.codes_otp SET envois = 0 WHERE numero = $1", [numero]);
    }
    expect((await moi(titulaire)).status).toBe(423);
    expect((await demander(numero, { codeSecret: "482615" })).r.status).toBe(423);
    await app.get(BlocagesService).leverEchus(new Date(Date.now() + 25 * HEURE_MS));
    expect((await moi(titulaire)).status).toBe(200);
  });
});

describe("compte bloqué : échéances suspendues, autres membres prévenus (règle du 03/11)", () => {
  it("ni retard ni défaut pendant le blocage ; au déblocage, les dates reculent d'autant", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
    const [bloque, autre] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
    const due = (await cotisationsDe(client, cercle.id, bloque)).find((c) => c.tour === 1)!;
    const blocages = app.get(BlocagesService);
    const planificateur = app.get(PlanificateurService);
    const debut = new Date(Date.parse(due.dateLimite) - 24 * HEURE_MS);
    const score = async (qui: Identite) =>
      (await json<{ defauts: number }>(await client.requete("GET", `/score/${qui.id}`, undefined, qui))).defauts;

    await blocages.bloquer(bloque.id, "opposition", debut);
    await app.get(FileSms).vider();
    for (const m of [beneficiaire, autre]) {
      expect(smsVers(await numeroDe(m)).at(-1)!.texte).toMatch(/bloqué/);
    }
    // Fin de grâce passée pendant le blocage : aucun défaut pour le membre bloqué, mais bien pour l'autre.
    const apresGrace = new Date(Date.parse(due.finGrace) + HEURE_MS);
    await planificateur.examinerEcheances(apresGrace);
    expect(await score(autre)).toBe(1);
    await blocages.lever(bloque.id, new Date(apresGrace.getTime() + HEURE_MS));
    expect(await score(bloque)).toBe(0);

    const dureeBlocage = apresGrace.getTime() + HEURE_MS - debut.getTime();
    const apres = (await cotisationsDe(client, cercle.id, bloque)).find((c) => c.id === due.id)!;
    expect(Date.parse(apres.dateLimite)).toBe(Date.parse(due.dateLimite) + dureeBlocage);
    expect(Date.parse(apres.finGrace)).toBe(Date.parse(due.finGrace) + dureeBlocage);
    await app.get(FileSms).vider();
    expect(smsVers(await numeroDe(autre)).at(-1)!.texte).toMatch(/débloqué/);

    // Le délai de grâce reprend : pas de défaut avant la nouvelle fin de grâce, défaut après.
    await planificateur.examinerEcheances(new Date(Date.parse(apres.finGrace) - HEURE_MS));
    expect(await score(bloque)).toBe(0);
    await planificateur.examinerEcheances(new Date(Date.parse(apres.finGrace) + HEURE_MS));
    expect(await score(bloque)).toBe(1);
  });
});
