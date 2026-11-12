import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { AppModule } from "./app.module.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base/base-de-donnees.js";
import { ContactConfianceService } from "./modules/comptes/contact-confiance.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "./sms/connecteur-sms.js";
import { FileSms } from "./sms/file-sms.js";
import { creerClient, type Identite } from "./testing/client.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;
let suivant = 0;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());

const CHEMIN = "/comptes/moi/contact-de-confiance";
/** Numéro fictif de contact, hors de la plage des membres de test. */
const numeroContact = () => `+2379${String(process.pid % 10000).padStart(4, "0")}${String(++suivant).padStart(4, "0")}`;

async function designer(membre: Identite, numero = numeroContact(), nom = "Tante Fictive") {
  const r = await client.requete("POST", CHEMIN, { nom, numero }, membre);
  await app.get(FileSms).vider();
  const sms = [...app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages].reverse().find((m) => m.numero === numero);
  return { r, numero, sms, code: /(\d{6})/.exec(sms?.texte ?? "")?.[1] };
}
const accord = (membre: Identite, code: string) => client.requete("POST", `${CHEMIN}/accord`, { code }, membre);
const lire = async (membre: Identite) => client.requete("GET", CHEMIN, undefined, membre);

describe("contact de confiance", () => {
  it("désignation : SMS au contact, sans engagement financier, accord par le code", async () => {
    const membre = await client.inscrire();
    expect((await lire(membre)).status).toBe(404);
    const { r, numero, sms, code } = await designer(membre);
    expect(r.status).toBe(201);
    expect(sms!.texte).toMatch(/aucun engagement financier/i);
    expect(await (await lire(membre)).json()).toMatchObject({ nom: "Tante Fictive", numero, statut: "en_attente" });
    expect(await app.get(ContactConfianceService).aUnContactConsentant(membre.id)).toBe(false);

    expect((await accord(membre, code!)).status).toBe(201);
    const contact = (await (await lire(membre)).json()) as { statut: string; consentementLe?: string };
    expect(contact.statut).toBe("accepte");
    expect(contact.consentementLe).toBeTruthy();
    expect(await app.get(ContactConfianceService).aUnContactConsentant(membre.id)).toBe(true);
    // Le code ne sert qu'une fois.
    expect((await accord(membre, code!)).status).toBe(400);
  });

  it("le code n'est jamais renvoyé ni gardé en clair avec le contact", async () => {
    const membre = await client.inscrire();
    const { r, code } = await designer(membre);
    expect(JSON.stringify(await r.json())).not.toContain(code);
    const lignes = await app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete("SELECT * FROM comptes.contacts_confiance WHERE compte_id = $1", [membre.id]);
    expect(JSON.stringify(lignes)).not.toContain(code);
  });

  it("mauvais code : refusé, et plus aucun essai après cinq erreurs", async () => {
    const membre = await client.inscrire();
    const { code } = await designer(membre);
    const faux = code === "000000" ? "111111" : "000000";
    for (let i = 0; i < 5; i++) expect((await accord(membre, faux)).status).toBe(400);
    expect((await accord(membre, code!)).status).toBe(400);
    expect(await app.get(ContactConfianceService).aUnContactConsentant(membre.id)).toBe(false);
  });

  it("code expiré après 48 h", async () => {
    const membre = await client.inscrire();
    const { code } = await designer(membre);
    await app
      .get<BaseDeDonnees>(BASE_DE_DONNEES)
      .requete("UPDATE comptes.contacts_confiance SET expire_le = now() - interval '1 minute' WHERE compte_id = $1", [
        membre.id,
      ]);
    expect((await accord(membre, code!)).status).toBe(400);
  });

  it("chacun ne gère que son propre contact : le code d'un autre ne vaut rien pour moi", async () => {
    const [a, b] = [await client.inscrire(), await client.inscrire()];
    const { code } = await designer(a);
    expect((await accord(b, code!)).status).toBe(400);
    expect((await lire(b)).status).toBe(404);
    expect((await client.requete("GET", CHEMIN)).status).toBe(401);
    expect((await client.requete("POST", CHEMIN, { nom: "X", numero: numeroContact() })).status).toBe(401);
  });

  it("refuse son propre numéro, un corps mal formé, et plus de trois désignations par jour", async () => {
    const membre = await client.inscrire();
    const moi = (await (await client.requete("GET", "/comptes/moi", undefined, membre)).json()) as { numero: string };
    expect((await designer(membre, moi.numero)).r.status).toBe(400);
    expect((await client.requete("POST", CHEMIN, { nom: "", numero: "abc" }, membre)).status).toBe(400);
    expect((await client.requete("POST", CHEMIN, { nom: "A", numero: numeroContact(), autre: 1 }, membre)).status).toBe(
      400,
    );
    for (let i = 0; i < 3; i++) expect((await designer(membre)).r.status).toBe(201);
    expect((await designer(membre)).r.status).toBe(429);
  });

  it("désigner un autre contact annule l'accord du précédent", async () => {
    const membre = await client.inscrire();
    const premier = await designer(membre);
    await accord(membre, premier.code!);
    const second = await designer(membre);
    expect(await (await lire(membre)).json()).toMatchObject({ numero: second.numero, statut: "en_attente" });
    expect((await accord(membre, premier.code!)).status).toBe(400);
  });
});
