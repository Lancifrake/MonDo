import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageInscription } from "./authentification/messages.js";
import { MIGRATIONS } from "./base/migrations.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { creerClient } from "./testing/client.js";
import { baseDeTest } from "./testing/base.js";
import { nouveauTelephone } from "./testing/telephone.js";
import { normaliserNumero, numeroValide } from "./validation/numero.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(async () => app.close());

/** Inscription d'un nouveau téléphone, le numéro écrit tel quel ; le code SMS est lu là où il est parti. */
async function inscrireAvec(numero: string) {
  const tel = await nouveauTelephone();
  const d = { numero, nom: "Même personne", clePublique: tel.clePublique };
  const demande = await client.requete("POST", "/comptes/otp", { numero });
  if (demande.status !== 201) throw new Error(`Code SMS refusé : ${demande.status}`);
  const sms = client.app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS);
  const message = [...sms.messages].reverse().find((m) => m.numero === normaliserNumero(numero));
  const codeOtp = /(\d{6})/.exec(message?.texte ?? "")![1]!;
  return client.requete("POST", "/comptes", { ...d, preuve: await tel.signer(messageInscription(d)), codeOtp });
}

describe("un téléphone, une seule écriture de son numéro (audit du 19/11, lacune 1)", () => {
  it("ramène les écritures courantes à la même forme", () => {
    for (const n of ["+237655443322", "237655443322", "00237655443322", "655443322"]) {
      expect(normaliserNumero(n)).toBe("+237655443322");
    }
    expect(normaliserNumero("+33612345678")).toBe("+33612345678");
    expect(normaliserNumero("0033612345678")).toBe("+33612345678");
    expect(numeroValide("0612345678")).toBeUndefined(); // numéro local sans indicatif : ambigu, refusé
    expect(numeroValide("+0612345678")).toBeUndefined();
  });

  it("un deuxième compte pour le même téléphone est refusé, quelle que soit l'écriture", async () => {
    const premier = await inscrireAvec("+237655443301");
    expect(premier.status).toBe(201);
    expect(((await premier.json()) as { numero: string }).numero).toBe("+237655443301");
    for (const autre of ["237655443301", "00237655443301", "655443301"]) {
      expect((await inscrireAvec(autre)).status).toBe(409);
    }
  });

  it("une inscription écrite sans « + » est acceptée et enregistrée sous la forme unique", async () => {
    const r = await inscrireAvec("237655443302");
    expect(r.status).toBe(201);
    expect(((await r.json()) as { numero: string }).numero).toBe("+237655443302");
  });

  it("la limite de codes SMS vaut pour le téléphone, pas pour chaque écriture", async () => {
    expect((await client.requete("POST", "/comptes/otp", { numero: "+237655443303" })).status).toBe(201);
    // Une minute entre deux codes : la deuxième écriture du même numéro est retenue par la même limite.
    expect((await client.requete("POST", "/comptes/otp", { numero: "00237655443303" })).status).toBe(429);
  });

  it("refuse un numéro sans forme possible", async () => {
    expect((await client.requete("POST", "/comptes/otp", { numero: "0612345678" })).status).toBe(400);
  });
});

describe("migration 035 : numéros déjà en base", () => {
  it("normalise, garde le plus ancien d'un doublon, et ne touche pas une forme déjà unique", async () => {
    const base = await baseDeTest();
    const cle = JSON.stringify({ kty: "EC", crv: "P-256", x: "x", y: "y" });
    const inserer = (numero: string, creeLe: string) =>
      base.requete(
        "INSERT INTO comptes.comptes (id, numero, nom, niveau, cle_publique, cree_le) VALUES ($1, $2, 'T', 1, $3, $4)",
        [randomUUID(), numero, cle, creeLe],
      );
    await inserer("237699000001", "2026-01-01T00:00:00Z"); // seul : devient +237699000001
    await inserer("00237699000002", "2026-01-01T00:00:00Z"); // le plus ancien des deux
    await inserer("699000002", "2026-02-01T00:00:00Z"); // doublon plus récent : garde son écriture
    await inserer("+237699000003", "2026-01-01T00:00:00Z"); // déjà unique
    await inserer("237699000003", "2026-02-01T00:00:00Z"); // doublon d'une forme déjà unique : inchangé
    const m = MIGRATIONS.find((x) => x.nom === "035_numeros_normalises")!;
    for (const instruction of m.sql
      .split(";")
      .map((s) => s.trim())
      .filter(Boolean))
      await base.requete(instruction);
    const numeros = (await base.requete<{ numero: string }>("SELECT numero FROM comptes.comptes ORDER BY numero")).map(
      (l) => l.numero,
    );
    expect(numeros).toEqual(["+237699000001", "+237699000002", "+237699000003", "237699000003", "699000002"]);
  });
});
