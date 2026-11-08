import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageInscription } from "./authentification/messages.js";
import { messageEngagement, messageReglement, type Cercle, type Reglement } from "./modules/cercles/cercles.service.js";
import { creerClient } from "./testing/client.js";
import { nouveauTelephone } from "./testing/telephone.js";
import { dansJours } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

describe("contraintes garanties par la base", () => {
  it("refuse deux comptes avec le même numéro", async () => {
    const [t1, t2] = [await nouveauTelephone(), await nouveauTelephone()];
    const inscrire = async (t: typeof t1) => {
      const d = { numero: "+237680000001", nom: "Doublon", clePublique: t.clePublique };
      return client.requete("POST", "/comptes", {
        ...d,
        preuve: await t.signer(messageInscription(d)),
        codeOtp: await client.codeOtp(d.numero),
      });
    };
    expect((await inscrire(t1)).status).toBe(201);
    expect((await inscrire(t2)).status).toBe(409);
  });

  it("refuse une clé publique qui contient une partie privée", async () => {
    const t = await nouveauTelephone();
    const d = { numero: "+237680000002", nom: "Fuite", clePublique: { ...t.clePublique, d: "secret" } };
    expect((await client.requete("POST", "/comptes", { ...d, preuve: "x" })).status).toBe(400);
  });

  it("deux adhésions simultanées pour la dernière place : une seule passe", async () => {
    const org = await client.inscrire();
    const r: Reglement = {
      montant: 10000,
      frequence: "hebdomadaire",
      nombreMembres: 3,
      penaliteRetard: 500,
      delaiGraceJours: 2,
      ouvert: false,
      datePremierTour: dansJours(7),
    };
    const cercle = (await (
      await client.requete(
        "POST",
        "/cercles",
        {
          reglement: r,
          placeSouhaitee: r.nombreMembres,
          signature: await org.signer(messageReglement(org.id, r, r.nombreMembres)),
        },
        org,
      )
    ).json()) as Cercle;
    const adherer = async (m: Awaited<ReturnType<typeof client.inscrire>>) =>
      client.requete(
        "POST",
        `/cercles/${cercle.id}/adhesions`,
        {
          placeSouhaitee: cercle.reglement.nombreMembres,
          signature: await m.signer(
            messageEngagement(cercle.id, cercle.empreinteReglement, m.id, cercle.reglement.nombreMembres),
          ),
        },
        m,
      );
    await adherer(await client.inscrire());
    const candidats = [await client.inscrire(), await client.inscrire(), await client.inscrire()];
    const statuts = (await Promise.all(candidats.map(adherer))).map((x) => x.status).sort();
    expect(statuts).toEqual([201, 400, 400]);
    const final = (await (await client.requete("GET", `/cercles/${cercle.id}`, undefined, org)).json()) as Cercle;
    expect(final.membres).toHaveLength(3);
    expect(final.statut).toBe("complet");
  });
});
