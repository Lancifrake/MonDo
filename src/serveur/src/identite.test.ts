import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import type { NestExpressApplication } from "@nestjs/platform-express";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { configurerApplication } from "./application.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { ComptesService } from "./modules/comptes/comptes.service.js";
import { DUREE_CONSERVATION_CARTE_ANS, IdentiteService } from "./modules/comptes/identite.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { STOCKAGE_OBJETS, type StockageObjets } from "./stockage/stockage-objets.js";
import { creerClient, type Identite } from "./testing/client.js";
import { avecContactConsentant, dossierIdentite, imageFictive } from "./testing/identite.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let admin: Identite;
let base: BaseDeDonnees;
let stockage: StockageObjets;

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
  stockage = app.get<StockageObjets>(STOCKAGE_OBJETS);
});
afterAll(async () => {
  delete process.env.MONDO_ADMINISTRATEURS;
  await app.close();
});
afterEach(() => vi.unstubAllEnvs());

const json = async <T>(r: Response) => (await r.json()) as T;
const DEPOT = "/comptes/moi/identite";
const ADMIN = "/administration/identites";

async function membrePret() {
  const membre = await client.inscrire();
  await avecContactConsentant(app, client, membre);
  return membre;
}
async function deposer(membre: Identite, corps: unknown = dossierIdentite()) {
  const r = await client.requete("POST", DEPOT, corps, membre);
  return { r, id: r.status === 201 ? (await json<{ id: string }>(r.clone())).id : "" };
}
const decider = (
  id: string,
  decision: "validee" | "refusee",
  qui: Identite = admin,
  motif = "Pièce lisible, visage conforme",
) => client.requete("POST", `${ADMIN}/${id}/decision`, { decision, motif }, qui);
const cles = async (id: string) =>
  base.requete<{ nature: string; cle_stockage: string; supprimee_le: unknown }>(
    "SELECT nature, cle_stockage, supprimee_le FROM comptes.pieces_identite WHERE verification_id = $1 ORDER BY nature",
    [id],
  );
const presente = async (cle: string) =>
  stockage.lire(cle).then(
    () => true,
    () => false,
  );

describe("dépôt des pièces", () => {
  it("exige un contact de confiance qui a donné son accord", async () => {
    const membre = await client.inscrire();
    const { r } = await deposer(membre);
    expect(r.status).toBe(403);
    expect((await json<{ message: string }>(r)).message).toMatch(/contact de confiance/);
  });

  it("dépôt accepté : en attente, consentement daté, images chiffrées hors de la base", async () => {
    const membre = await membrePret();
    const { r, id } = await deposer(membre);
    expect(r.status).toBe(201);
    const recu = await json<Record<string, unknown>>(r);
    expect(recu).toMatchObject({ statut: "en_attente", typePiece: "cni" });
    expect(recu.consentementLe).toBeTruthy();
    expect(JSON.stringify(recu)).not.toContain(dossierIdentite().recto);
    // La base ne contient que la clé de stockage et une empreinte, jamais l'image.
    const lignes = await base.requete("SELECT * FROM comptes.pieces_identite WHERE verification_id = $1", [id]);
    expect(lignes).toHaveLength(3);
    expect(JSON.stringify(lignes)).not.toContain(dossierIdentite().recto);
    for (const p of await cles(id)) expect(await presente(p.cle_stockage)).toBe(true);
    expect(await json(await client.requete("GET", DEPOT, undefined, membre))).toMatchObject({ statut: "en_attente" });
    expect((await app.get(ComptesService).trouver(membre.id)).niveau).toBe(1);
  });

  it("accepte des images de taille réelle (corps de plusieurs mégaoctets)", async () => {
    const membre = await membrePret();
    const grande = imageFictive(900_000, 7).toString("base64");
    const { r } = await deposer(membre, dossierIdentite({ recto: grande, verso: grande, selfie: grande }));
    expect(r.status).toBe(201);
  });

  it("refuse sans consentement explicite, avec une autre version du texte, ou un corps inattendu", async () => {
    const membre = await membrePret();
    expect((await deposer(membre, dossierIdentite({ consentement: false }))).r.status).toBe(400);
    const { consentement: _c, ...sans } = dossierIdentite();
    expect((await deposer(membre, sans)).r.status).toBe(400);
    expect((await deposer(membre, dossierIdentite({ versionConsentement: "2020-01-01" }))).r.status).toBe(400);
    expect((await deposer(membre, dossierIdentite({ champEnTrop: 1 }))).r.status).toBe(400);
    expect((await deposer(membre, dossierIdentite({ typePiece: "permis" }))).r.status).toBe(400);
  });

  it("refuse ce qui n'est ni un JPEG ni un PNG, une image trop lourde, et un second dépôt en attente", async () => {
    const membre = await membrePret();
    const texte = Buffer.from("ceci n'est pas une image").toString("base64");
    expect((await deposer(membre, dossierIdentite({ selfie: texte }))).r.status).toBe(400);
    const lourde = imageFictive(2 * 1024 * 1024 + 10).toString("base64");
    expect((await deposer(membre, dossierIdentite({ recto: lourde }))).r.status).toBe(400);
    expect((await deposer(membre)).r.status).toBe(201);
    expect((await deposer(membre)).r.status).toBe(409);
  });

  it("requête non signée refusée ; mon dossier n'est lisible que par moi", async () => {
    expect((await client.requete("POST", DEPOT, dossierIdentite())).status).toBe(401);
    expect((await client.requete("GET", DEPOT)).status).toBe(401);
    const autre = await client.inscrire();
    expect((await client.requete("GET", DEPOT, undefined, autre)).status).toBe(404);
  });
});

describe("taille des corps de requête", () => {
  const poster = async (chemin: string, corps: string) =>
    fetch((await app.getUrl()) + chemin, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: corps,
    });

  it("le dépôt des pièces refuse plus de 9 Mo, et un JSON invalide, avant toute autre vérification", async () => {
    expect((await poster(DEPOT, JSON.stringify({ recto: "A".repeat(10 * 1024 * 1024) }))).status).toBe(413);
    expect((await poster(DEPOT, "{pas du json")).status).toBe(400);
  });

  it("partout ailleurs, la limite ordinaire de 100 ko reste en place", async () => {
    expect((await poster("/comptes/otp", JSON.stringify({ numero: "1".repeat(200_000) }))).status).toBe(413);
  });
});

describe("file d'attente et décision de l'Administrateur", () => {
  it("réservée à l'Administrateur : liste, lecture d'une pièce, décision", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    const autre = await client.inscrire();
    for (const qui of [membre, autre]) {
      expect((await client.requete("GET", ADMIN, undefined, qui)).status).toBe(403);
      expect((await client.requete("GET", `${ADMIN}/${id}/pieces/recto`, undefined, qui)).status).toBe(403);
      expect((await decider(id, "validee", qui)).status).toBe(403);
    }
    expect((await client.requete("GET", ADMIN)).status).toBe(401);
    expect((await app.get(ComptesService).trouver(membre.id)).niveau).toBe(1);
  });

  it("l'Administrateur voit le dossier et ouvre une pièce ; chaque ouverture est journalisée", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    const file = await json<Record<string, unknown>[]>(await client.requete("GET", ADMIN, undefined, admin));
    const dossier = file.find((d) => d.id === id)!;
    expect(dossier).toMatchObject({ compteId: membre.id, typePiece: "cni" });
    expect(dossier.nom).toMatch(/^Membre/);
    expect(JSON.stringify(file)).not.toContain(dossierIdentite().recto);

    const piece = await json<{ contenu: string; type: string }>(
      await client.requete("GET", `${ADMIN}/${id}/pieces/recto`, undefined, admin),
    );
    expect(piece).toMatchObject({ contenu: dossierIdentite().recto, type: "image/jpeg" });
    expect((await client.requete("GET", `${ADMIN}/${id}/pieces/autre`, undefined, admin)).status).toBe(404);
    const acces = await base.requete("SELECT * FROM comptes.acces_pieces WHERE verification_id = $1", [id]);
    expect(acces).toMatchObject([{ nature: "recto", administrateur_id: admin.id }]);
  });

  it("validée : niveau 2, selfie supprimé tout de suite, carte gardée, décision au registre, SMS au membre", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    const avant = await base.requete("SELECT id FROM registre.empreintes");
    const r = await decider(id, "validee");
    expect(r.status).toBe(201);
    expect(await json(r)).toMatchObject({ statut: "validee" });
    expect((await app.get(ComptesService).trouver(membre.id)).niveau).toBe(2);
    for (const p of await cles(id)) {
      expect(await presente(p.cle_stockage)).toBe(p.nature !== "selfie");
      expect(Boolean(p.supprimee_le)).toBe(p.nature === "selfie");
    }
    expect((await base.requete("SELECT id FROM registre.empreintes")).length).toBe(avant.length + 1);
    await app.get(FileSms).vider();
    const moi = await json<{ numero: string }>(await client.requete("GET", "/comptes/moi", undefined, membre));
    const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages.filter((m) => m.numero === moi.numero);
    expect(sms.at(-1)!.texte).toMatch(/identité vérifiée/i);
    // Une décision ne se rejoue pas, et la pièce ne s'ouvre plus après.
    expect((await decider(id, "refusee")).status).toBe(400);
    expect((await client.requete("GET", `${ADMIN}/${id}/pieces/recto`, undefined, admin)).status).toBe(400);
    expect((await deposer(membre)).r.status).toBe(409);
  });

  it("refusée : niveau 1, motif rendu au membre, toutes les images supprimées, nouveau dépôt possible", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    expect((await decider(id, "refusee", admin, "Photo floue")).status).toBe(201);
    expect((await app.get(ComptesService).trouver(membre.id)).niveau).toBe(1);
    for (const p of await cles(id)) expect(await presente(p.cle_stockage)).toBe(false);
    expect(await json(await client.requete("GET", DEPOT, undefined, membre))).toMatchObject({
      statut: "refusee",
      motifDecision: "Photo floue",
    });
    expect((await deposer(membre)).r.status).toBe(201);
  });

  it("un Administrateur ne décide pas de sa propre identité ; décision mal formée refusée", async () => {
    await avecContactConsentant(app, client, admin);
    const { id } = await deposer(admin);
    expect((await decider(id, "validee")).status).toBe(403);
    const second = await client.inscrire();
    vi.stubEnv("MONDO_ADMINISTRATEURS", `${admin.id},${second.id}`);
    expect(
      (await client.requete("POST", `${ADMIN}/${id}/decision`, { decision: "peut-etre", motif: "x" }, second)).status,
    ).toBe(400);
    expect((await client.requete("POST", `${ADMIN}/${id}/decision`, { decision: "validee" }, second)).status).toBe(400);
    expect((await decider("00000000-0000-4000-8000-000000000000", "validee", second)).status).toBe(404);
    expect((await decider(id, "validee", second)).status).toBe(201);
  });

  it("deux décisions simultanées : une seule passe", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    const second = await client.inscrire();
    vi.stubEnv("MONDO_ADMINISTRATEURS", `${admin.id},${second.id}`);
    const statuts = (await Promise.all([decider(id, "validee"), decider(id, "refusee", second)])).map((r) => r.status);
    expect(statuts.sort()).toEqual([201, 400]);
  });
});

describe("conservation", () => {
  const AN_MS = 365.25 * 24 * 60 * 60 * 1000;

  it("la carte est supprimée 5 ans après le dernier cercle du membre, jamais tant qu'il a un cercle en cours", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    await decider(id, "validee");
    const identite = app.get(IdentiteService);
    const plusTard = new Date(Date.now() + (DUREE_CONSERVATION_CARTE_ANS + 0.1) * AN_MS);
    const carte = (await cles(id)).filter((p) => p.nature !== "selfie");

    const gardee = async () => (await Promise.all(carte.map((p) => presente(p.cle_stockage)))).every(Boolean);
    const sansCercle = async () => false;

    await identite.purger(new Date(Date.now() + 4 * AN_MS), sansCercle);
    expect(await gardee()).toBe(true);
    // Délai passé, mais le membre a un cercle en cours : on garde.
    await identite.purger(plusTard, async (id) => id === membre.id);
    expect(await gardee()).toBe(true);

    // Un cercle du membre se termine dans 3 ans : la carte est gardée 5 ans de plus à partir de là.
    await identite.noterFinDeCercle(membre.id, new Date(Date.now() + 3 * AN_MS));
    await identite.purger(plusTard, sansCercle);
    expect(await gardee()).toBe(true);
    expect(await identite.purger(new Date(Date.now() + 8.2 * AN_MS), sansCercle)).toBeGreaterThanOrEqual(2);
    for (const p of carte) expect(await presente(p.cle_stockage)).toBe(false);
    // Le niveau 2 reste acquis ; rejouer la purge ne fait plus rien.
    expect((await app.get(ComptesService).trouver(membre.id)).niveau).toBe(2);
    expect(await identite.purger(new Date(Date.now() + 9 * AN_MS), sansCercle)).toBe(0);
  });

  it("une suppression de selfie manquée (stockage en panne) est reprise par la purge", async () => {
    const membre = await membrePret();
    const { id } = await deposer(membre);
    const supprimer = vi.spyOn(stockage, "supprimer").mockRejectedValueOnce(new Error("panne fictive"));
    expect((await decider(id, "validee")).status).toBe(201);
    supprimer.mockRestore();
    const selfie = (await cles(id)).find((p) => p.nature === "selfie")!;
    expect(await presente(selfie.cle_stockage)).toBe(true);
    expect(await app.get(IdentiteService).purger(new Date(), async () => true)).toBeGreaterThanOrEqual(1);
    expect(await presente(selfie.cle_stockage)).toBe(false);
  });
});

describe("raccourci de démonstration", () => {
  it("en production, le niveau 2 ne s'obtient que par ce circuit", async () => {
    const membre = await client.inscrire();
    vi.stubEnv("NODE_ENV", "production");
    const r = await membre.niveau2();
    expect(r.status).toBe(403);
    expect((await json<{ message: string }>(r)).message).toMatch(/\/comptes\/moi\/identite/);
  });
});
