import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;

interface EtatDuCercle {
  tours: {
    numero: number;
    beneficiaireId: string;
    dateLimite: string;
    paiements: { payeurId: string; statut: string; enRetard: boolean; penaliteDue: number }[];
  }[];
}

describe("qui a payé, qui n'a pas payé : l'état de chaque tour pour tout le cercle (US17)", () => {
  it("chaque membre voit tous les paiements de chaque tour, sans référence de transaction", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
    const [payeur, autre] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
    const due = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1 && c.payeurId === payeur.id)!;
    await client.requete("POST", `/cotisations/${due.id}/paiement`, { referenceTransaction: "OM-SECRET-42" }, payeur);

    const r = await client.requete("GET", `/cotisations/cercles/${cercle.id}/etat`, undefined, autre);
    expect(r.status).toBe(200);
    const etat = await json<EtatDuCercle>(r);
    expect(etat.tours.map((t) => t.numero)).toEqual([1, 2, 3]);
    const tour1 = etat.tours[0]!;
    expect(tour1.beneficiaireId).toBe(beneficiaire.id);
    expect(tour1.paiements).toHaveLength(2);
    expect(tour1.paiements.find((p) => p.payeurId === payeur.id)).toMatchObject({
      statut: "declaree",
      enRetard: false,
    });
    expect(tour1.paiements.find((p) => p.payeurId === autre.id)).toMatchObject({ statut: "due", enRetard: false });
    expect(JSON.stringify(etat)).not.toContain("OM-SECRET-42");
  });

  it("un paiement non fait après la date limite apparaît en retard", async () => {
    const { membres, cercle } = await cercleComplet(client);
    await app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete(
        "UPDATE cotisations.cotisations SET date_limite = now() - interval '1 hour' WHERE cercle_id = $1 AND tour = 1",
        [cercle.id],
      );
    const etat = await json<EtatDuCercle>(
      await client.requete("GET", `/cotisations/cercles/${cercle.id}/etat`, undefined, membres[0]),
    );
    expect(etat.tours[0]!.paiements.every((p) => p.enRetard)).toBe(true);
  });

  it("réservé aux membres d'un cercle en cours ; requête signée", async () => {
    const { cercle } = await cercleComplet(client);
    const etranger = await client.inscrire();
    expect((await client.requete("GET", `/cotisations/cercles/${cercle.id}/etat`, undefined, etranger)).status).toBe(
      403,
    );
    expect((await client.requete("GET", `/cotisations/cercles/${cercle.id}/etat`)).status).toBe(401);
    const org = await client.inscrire();
    const attente = await json<{ id: string }>(await creerCercle(client, org, reglementDeTest()));
    expect((await client.requete("GET", `/cotisations/cercles/${attente.id}/etat`, undefined, org)).status).toBe(403);
  });
});

describe("score : historique pour soi, explication pour tous ceux qui le voient (M6)", () => {
  it("le membre voit son historique et l'explication ; un membre du même cercle, l'explication seulement", async () => {
    const { membres, cercle } = await cercleComplet(client);
    const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
    const payeur = membres.find((m) => m !== beneficiaire)!;
    const due = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1 && c.payeurId === payeur.id)!;
    await client.requete("POST", `/cotisations/${due.id}/paiement`, { referenceTransaction: "OM-1" }, payeur);
    await client.requete("POST", `/cotisations/${due.id}/confirmation`, undefined, beneficiaire);

    const moi = await json<
      Record<string, unknown> & { historique: { type: string; scoreApres: number }[]; explication: string[] }
    >(await client.requete("GET", `/score/${payeur.id}`, undefined, payeur));
    expect(moi.historique).toEqual([expect.objectContaining({ type: "cotisation_a_temps", points: 2, scoreApres: 2 })]);
    expect(moi.explication.join(" ")).toMatch(/1 cotisation payée à temps/);

    const vuParAutre = await json<Record<string, unknown>>(
      await client.requete("GET", `/score/${payeur.id}`, undefined, beneficiaire),
    );
    expect(vuParAutre).toHaveProperty("explication");
    expect(vuParAutre).not.toHaveProperty("historique");
  });
});
