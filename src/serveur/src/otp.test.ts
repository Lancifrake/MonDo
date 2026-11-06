import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { messageInscription } from "./authentification/messages.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { OtpService } from "./modules/comptes/otp.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { creerClient } from "./testing/client.js";
import { nouveauTelephone } from "./testing/telephone.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let sms: ConnecteurSmsSimule;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
  sms = app.get(CONNECTEUR_SMS);
});
afterAll(async () => app.close());

let suivant = 0;
const numeroNeuf = () => `+23765${String(++suivant).padStart(7, "0")}`;
const dernierCode = (numero: string) => {
  const m = [...sms.messages].reverse().find((x) => x.numero === numero);
  return /(\d{6})/.exec(m?.texte ?? "")?.[1];
};

async function inscrireAvecCode(numero: string, codeOtp: string | undefined) {
  const tel = await nouveauTelephone();
  const d = { numero, nom: "Awa", clePublique: tel.clePublique };
  return client.requete("POST", "/comptes", { ...d, preuve: await tel.signer(messageInscription(d)), codeOtp });
}

describe("code SMS à l'inscription (simulé)", () => {
  it("le code reçu par SMS permet de s'inscrire", async () => {
    const numero = numeroNeuf();
    expect((await client.requete("POST", "/comptes/otp", { numero })).status).toBe(201);
    const code = dernierCode(numero);
    expect(code).toMatch(/^\d{6}$/);
    expect((await inscrireAvecCode(numero, code)).status).toBe(201);
  });

  it("sans code, ou avec un mauvais code, l'inscription est refusée", async () => {
    const numero = numeroNeuf();
    await client.requete("POST", "/comptes/otp", { numero });
    expect((await inscrireAvecCode(numero, undefined)).status).toBe(400);
    const faux = dernierCode(numero) === "000000" ? "111111" : "000000";
    expect((await inscrireAvecCode(numero, faux)).status).toBe(403);
  });

  it("le code d'un numéro ne vaut pas pour un autre", async () => {
    const [a, b] = [numeroNeuf(), numeroNeuf()];
    await client.requete("POST", "/comptes/otp", { numero: a });
    await client.requete("POST", "/comptes/otp", { numero: b });
    expect((await inscrireAvecCode(b, dernierCode(a))).status).toBe(403);
  });

  it("après 5 essais ratés, même le bon code est refusé", async () => {
    const numero = numeroNeuf();
    await client.requete("POST", "/comptes/otp", { numero });
    const bon = dernierCode(numero)!;
    const faux = bon === "000000" ? "111111" : "000000";
    for (let i = 0; i < 5; i++) await inscrireAvecCode(numero, faux);
    expect((await inscrireAvecCode(numero, bon)).status).toBe(403);
  });

  it("un code ne sert qu'une fois", async () => {
    const otp = app.get(OtpService);
    const numero = numeroNeuf();
    await otp.demander(numero);
    const code = dernierCode(numero)!;
    expect(await otp.verifier(numero, code)).toBe(true);
    expect(await otp.verifier(numero, code)).toBe(false);
  });

  it("un code expire après 5 minutes", async () => {
    const otp = app.get(OtpService);
    const numero = numeroNeuf();
    await otp.demander(numero);
    const dans6min = new Date(Date.now() + 6 * 60 * 1000);
    expect(await otp.verifier(numero, dernierCode(numero)!, dans6min)).toBe(false);
  });

  it("pas de nouveau code avant une minute tant que le précédent n'a pas servi", async () => {
    const numero = numeroNeuf();
    expect((await client.requete("POST", "/comptes/otp", { numero })).status).toBe(201);
    expect((await client.requete("POST", "/comptes/otp", { numero })).status).toBe(429);
  });

  it("au plus 5 codes par numéro sur 24 h, même en attendant entre deux demandes (fraude au SMS)", async () => {
    const otp = app.get(OtpService);
    const numero = numeroNeuf();
    const t0 = Date.now();
    const a = (minutes: number) => new Date(t0 + minutes * 60 * 1000);
    for (let i = 0; i < 5; i++) await otp.demander(numero, a(2 * i));
    await expect(otp.demander(numero, a(20))).rejects.toThrow(/demain/);
    await expect(otp.demander(numero, a(23 * 60))).rejects.toThrow(/demain/);
    await expect(otp.demander(numero, a(24 * 60 + 1))).resolves.toBeDefined();
  });

  it("deux demandes simultanées pour le même numéro : un seul code envoyé", async () => {
    const otp = app.get(OtpService);
    const numero = numeroNeuf();
    const avant = sms.messages.filter((m) => m.numero === numero).length;
    const issues = await Promise.allSettled([otp.demander(numero), otp.demander(numero), otp.demander(numero)]);
    expect(issues.filter((i) => i.status === "fulfilled")).toHaveLength(1);
    expect(sms.messages.filter((m) => m.numero === numero).length - avant).toBe(1);
  });

  it("le code n'est jamais stocké en clair", async () => {
    const numero = numeroNeuf();
    await client.requete("POST", "/comptes/otp", { numero });
    const code = dernierCode(numero)!;
    const lignes = await app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete("SELECT * FROM comptes.codes_otp WHERE numero = $1", [numero]);
    expect(JSON.stringify(lignes)).not.toContain(code);
  });

  it("refuse un numéro invalide", async () => {
    expect((await client.requete("POST", "/comptes/otp", { numero: "abc" })).status).toBe(400);
  });
});
