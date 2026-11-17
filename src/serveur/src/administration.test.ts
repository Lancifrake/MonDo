import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type {
  CercleListe,
  CompteListe,
  EvenementJournal,
  SanteSysteme,
  TableauDeBord,
} from "./modules/administration/administration.service.js";
import { RegistreService } from "./registre/registre.service.js";
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
  process.env.MONDO_ADMINISTRATEURS = admin.id;
});
afterAll(async () => {
  delete process.env.MONDO_ADMINISTRATEURS;
  await app.close();
});

const json = async <T>(r: Response) => (await r.json()) as T;
const base = () => app.get<BaseDeDonnees>(BASE_DE_DONNEES);

describe("comptes vus par l'administrateur", () => {
  it("liste nom, numéro, niveau, cercles actifs et blocage ; refusé à un simple membre", async () => {
    const { membres } = await cercleComplet(client, reglementDeTest());
    const [m1, m2] = membres as [Identite, Identite];
    await base().requete(
      "INSERT INTO comptes.blocages (id, compte_id, motif, bloque_le) VALUES (gen_random_uuid(), $1, 'opposition', now())",
      [m2.id],
    );
    const r = await client.requete("GET", "/administration/comptes", undefined, admin);
    expect(r.status).toBe(200);
    const comptes = await json<CompteListe[]>(r);
    const moi = await json<{ nom: string; numero: string }>(await client.requete("GET", "/comptes/moi", undefined, m1));
    expect(comptes.find((c) => c.id === m1.id)).toMatchObject({
      nom: moi.nom,
      numero: moi.numero,
      niveau: 1,
      cerclesActifs: 1,
      blocage: null,
      verificationEnAttente: false,
      administrateur: false,
    });
    expect(comptes.find((c) => c.id === m2.id)?.blocage).toMatchObject({ motif: "opposition" });
    // L'administrateur est dans la liste mais reconnaissable : il n'est pas un utilisateur.
    expect(comptes.find((c) => c.id === admin.id)?.administrateur).toBe(true);
    // Ni clé publique ni pièce : rien d'autre que ces champs ne sort.
    expect(Object.keys(comptes[0]!).sort()).toEqual(
      [
        "administrateur",
        "blocage",
        "cerclesActifs",
        "creeLe",
        "id",
        "niveau",
        "nom",
        "numero",
        "verificationEnAttente",
      ].sort(),
    );
    expect((await client.requete("GET", "/administration/comptes", undefined, m1)).status).toBe(403);
    expect((await client.requete("GET", "/administration/comptes")).status).toBe(401);
  });
});

describe("cercles vus par l'administrateur", () => {
  it("liste l'organisateur, le règlement, les membres et la progression des tours ; refusé à un simple membre", async () => {
    const { membres, cercle } = await cercleComplet(client, reglementDeTest());
    const [org] = membres as [Identite];
    const r = await client.requete("GET", "/administration/cercles", undefined, admin);
    expect(r.status).toBe(200);
    const ligne = (await json<CercleListe[]>(r)).find((c) => c.id === cercle.id)!;
    const moi = await json<{ nom: string }>(await client.requete("GET", "/comptes/moi", undefined, org));
    expect(ligne).toMatchObject({
      statut: "complet",
      organisateur: { nom: moi.nom },
      reglement: { montant: 10000, nombreMembres: 3 },
      membres: 3,
      toursTotal: 3,
      toursTermines: 0,
      litigesOuverts: 0,
    });

    // Un tour dont toutes les cotisations sont confirmées compte comme terminé.
    for (const m of membres as Identite[]) {
      for (const c of (await cotisationsDe(client, cercle.id, m)).filter((k) => k.tour === 1)) {
        await base().requete("UPDATE cotisations.cotisations SET statut = 'confirmee' WHERE id = $1", [c.id]);
      }
    }
    const apres = (
      await json<CercleListe[]>(await client.requete("GET", "/administration/cercles", undefined, admin))
    ).find((c) => c.id === cercle.id)!;
    expect(apres.toursTermines).toBe(1);
    expect((await client.requete("GET", "/administration/cercles", undefined, org)).status).toBe(403);
  });
});

describe("tableau de bord vu par l'administrateur", () => {
  it("compte les comptes, cercles, litiges et files à traiter, avec 30 points par série", async () => {
    const { membres } = await cercleComplet(client, reglementDeTest());
    const r = await client.requete("GET", "/administration/tableau-de-bord", undefined, admin);
    expect(r.status).toBe(200);
    const t = await json<TableauDeBord>(r);
    // Les administrateurs ne comptent pas parmi les utilisateurs : le total est celui de la liste sans eux.
    const liste = await json<CompteListe[]>(await client.requete("GET", "/administration/comptes", undefined, admin));
    expect(t.comptes.valeur).toBe(liste.filter((c) => !c.administrateur).length);
    expect(t.comptes.valeur).toBeGreaterThanOrEqual(membres.length);
    expect(t.comptes.derniers30Jours).toBe(t.comptes.valeur);
    expect(t.cercles.enCours).toBeGreaterThanOrEqual(1);
    for (const i of [t.comptes, t.cercles, t.cotisations, t.identitesEnAttente, t.litiges, t.defauts]) {
      expect(i.serie).toHaveLength(30);
    }
    // La série quotidienne des comptes retombe sur le total inscrit sur 30 jours.
    expect(t.comptes.serie.reduce((a, b) => a + b, 0)).toBe(t.comptes.derniers30Jours);
    expect(t.volumeParMois).toHaveLength(6);
    expect(t.aTraiter).toEqual({ litiges: 0, recuperations: 0, identites: 0, sommesDues: 0, defauts: 0 });
    expect(t.activite.length).toBeGreaterThan(0);
    expect(
      (await client.requete("GET", "/administration/tableau-de-bord", undefined, membres[0] as Identite)).status,
    ).toBe(403);
  });
});

describe("journal, vérification du registre et santé", () => {
  it("le journal liste des empreintes sans contenu, la vérification passe, puis détecte une empreinte retouchée", async () => {
    const { cercle } = await cercleComplet(client, reglementDeTest());
    await app.get(RegistreService).fermerLot();
    const j = await client.requete("GET", "/administration/journal?limite=500", undefined, admin);
    expect(j.status).toBe(200);
    const evenements = await json<EvenementJournal[]>(j);
    const duCercle = evenements.filter((e) => e.cercle?.id === cercle.id);
    expect(duCercle.length).toBeGreaterThan(0);
    expect(duCercle.every((e) => e.statut !== "en_attente")).toBe(true);
    expect(Object.keys(evenements[0]!).sort()).toEqual([
      "cercle",
      "empreinte",
      "enregistreLe",
      "id",
      "lot",
      "objet",
      "statut",
    ]);
    const figee = duCercle.find((e) => e.lot !== null)!;
    expect(figee.lot!.racine).toMatch(/^[0-9a-f]{64}$/);
    expect(figee.lot!.referenceInscription).toBeTruthy();
    expect(figee.statut).toBe("inscrite");

    const ok = await json<{ lots: number; alteres: number }>(
      await client.requete("GET", "/administration/registre/verification", undefined, admin),
    );
    expect(ok.lots).toBeGreaterThan(0);
    expect(ok.alteres).toBe(0);

    await base().requete(
      "UPDATE registre.empreintes SET empreinte = 'retouchee' WHERE id = (SELECT max(id) FROM registre.empreintes WHERE lot_id IS NOT NULL)",
    );
    const apres = await json<{ alteres: number }>(
      await client.requete("GET", "/administration/registre/verification", undefined, admin),
    );
    expect(apres.alteres).toBe(1);
  });

  it("la santé donne la file SMS, le registre et ce qui est simulé ; refusée à un simple membre", async () => {
    const r = await client.requete("GET", "/administration/sante", undefined, admin);
    expect(r.status).toBe(200);
    const s = await json<SanteSysteme>(r);
    expect(s).toMatchObject({ base: "ok", simules: { sms: true, registre: true } });
    expect(s.sms.echecs).toBe(0);
    expect(s.registre.empreintes).toBeGreaterThan(0);
    const membre = await client.inscrire();
    expect((await client.requete("GET", "/administration/sante", undefined, membre)).status).toBe(403);
    expect((await client.requete("GET", "/administration/journal", undefined, membre)).status).toBe(403);
  });
});
