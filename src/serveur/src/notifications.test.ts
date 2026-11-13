import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cercleComplet, cotisationsDe } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const json = async <T>(r: Response) => (await r.json()) as T;

interface Boite {
  nonLues: number;
  notifications: { id: string; texte: string; creeeLe: string; lueLe?: string }[];
}
const boite = async (qui?: Identite) => json<Boite>(await client.requete("GET", "/notifications", undefined, qui));

/** Un litige ouvert par le bénéficiaire : les deux parties sont prévenues. */
async function litigeOuvert() {
  const { membres, cercle } = await cercleComplet(client);
  const beneficiaire = membres.find((m) => m.id === cercle.ordre![0]!.membreId)!;
  const [payeur, tiers] = membres.filter((m) => m !== beneficiaire) as [Identite, Identite];
  const due = (await cotisationsDe(client, cercle.id, payeur)).find((c) => c.tour === 1 && c.payeurId === payeur.id)!;
  await client.requete("POST", `/cotisations/${due.id}/paiement`, { referenceTransaction: "OM-7" }, payeur);
  await client.requete("POST", "/litiges", { cotisationId: due.id, motif: "Rien reçu" }, beneficiaire);
  return { beneficiaire, payeur, tiers };
}

describe("notifications dans l'application (cahier des charges, M5)", () => {
  it("chaque message adressé à un membre arrive aussi dans sa boîte, non lu", async () => {
    const { beneficiaire, payeur, tiers } = await litigeOuvert();
    for (const qui of [beneficiaire, payeur]) {
      const b = await boite(qui);
      expect(b.nonLues).toBe(1);
      expect(b.notifications[0]!.texte).toMatch(/litige ouvert/);
      expect(b.notifications[0]).not.toHaveProperty("lueLe");
    }
    expect((await boite(tiers)).notifications).toEqual([]);
  });

  it("marquer une notification lue, puis toutes ; jamais celles d'un autre", async () => {
    const { beneficiaire, payeur } = await litigeOuvert();
    const [n] = (await boite(payeur)).notifications;
    expect((await client.requete("POST", `/notifications/${n!.id}/lue`, undefined, beneficiaire)).status).toBe(404);
    expect((await client.requete("POST", `/notifications/${n!.id}/lue`, undefined, payeur)).status).toBe(201);
    expect((await boite(payeur)).nonLues).toBe(0);
    expect((await boite(beneficiaire)).nonLues).toBe(1);
    expect((await client.requete("POST", "/notifications/lues", undefined, beneficiaire)).status).toBe(201);
    expect((await boite(beneficiaire)).nonLues).toBe(0);
    expect((await client.requete("POST", "/notifications/pas-un-id/lue", undefined, payeur)).status).toBe(404);
  });

  it("requête signée", async () => {
    expect((await client.requete("GET", "/notifications")).status).toBe(401);
    expect((await client.requete("POST", "/notifications/lues")).status).toBe(401);
  });
});
