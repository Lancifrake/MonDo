import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import type { CercleListe, CompteListe } from "./modules/administration/administration.service.js";
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
    });
    expect(comptes.find((c) => c.id === m2.id)?.blocage).toMatchObject({ motif: "opposition" });
    expect(comptes.some((c) => c.id === admin.id)).toBe(true);
    // Ni clé publique ni pièce : rien d'autre que ces champs ne sort.
    expect(Object.keys(comptes[0]!).sort()).toEqual(
      ["blocage", "cerclesActifs", "creeLe", "id", "niveau", "nom", "numero", "verificationEnAttente"].sort(),
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
