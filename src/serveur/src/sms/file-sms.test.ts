import { afterEach, beforeEach, describe, expect, it } from "vitest";
import type { BaseDeDonnees } from "../base/base-de-donnees.js";
import { baseDeTest } from "../testing/base.js";
import type { ConnecteurSms } from "./connecteur-sms.js";
import { FileSms, TENTATIVES_MAX } from "./file-sms.js";

/** Passerelle factice : peut tomber en panne, et compte ce qu'elle a vraiment envoyé. */
class PasserelleFactice implements ConnecteurSms {
  envoyes: { numero: string; texte: string }[] = [];
  enPanne = false;
  async envoyer(numero: string, texte: string) {
    await new Promise((r) => setTimeout(r, 1));
    if (this.enPanne) throw new Error("passerelle injoignable");
    this.envoyes.push({ numero, texte });
  }
}

let base: BaseDeDonnees;
let passerelle: PasserelleFactice;
let file: FileSms;

beforeEach(async () => {
  base = await baseDeTest();
  passerelle = new PasserelleFactice();
  file = new FileSms(base, passerelle);
});
afterEach(async () => {
  await file.onModuleDestroy();
  await base.fermer();
});

const statut = async (cle: string) =>
  (
    await base.requete<{ statut: string; tentatives: number }>(
      "SELECT statut, tentatives FROM sms.envois WHERE cle = $1",
      [cle],
    )
  )[0];

describe("file d'envoi des SMS", () => {
  it("mis en file puis envoyé une seule fois, même si on vide la file plusieurs fois", async () => {
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    await file.vider();
    await file.vider();
    expect(passerelle.envoyes).toEqual([{ numero: "+237600000001", texte: "Bonjour" }]);
    expect(await statut("a")).toMatchObject({ statut: "envoye", tentatives: 1 });
  });

  it("même clé mise en file deux fois (événement rejoué) : un seul SMS", async () => {
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    await file.vider();
    expect(passerelle.envoyes).toHaveLength(1);
  });

  it("passerelle en panne : le message attend, puis part quand elle revient", async () => {
    passerelle.enPanne = true;
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    await file.vider();
    expect(await statut("a")).toMatchObject({ statut: "a_envoyer", tentatives: 1 });
    passerelle.enPanne = false;
    await file.vider();
    expect(passerelle.envoyes).toHaveLength(1);
    expect(await statut("a")).toMatchObject({ statut: "envoye", tentatives: 2 });
  });

  it(`abandonné après ${TENTATIVES_MAX} échecs, plus jamais retenté (valeur limite)`, async () => {
    passerelle.enPanne = true;
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    for (let i = 0; i < TENTATIVES_MAX + 2; i++) await file.vider();
    expect(await statut("a")).toMatchObject({ statut: "echec", tentatives: TENTATIVES_MAX });
    passerelle.enPanne = false;
    await file.vider();
    expect(passerelle.envoyes).toHaveLength(0);
  });

  it("deux serveurs vident la file en même temps : chaque SMS ne part qu'une fois", async () => {
    const autreServeur = new FileSms(base, passerelle);
    for (let i = 0; i < 5; i++) await file.mettreEnFile(`m${i}`, "+237600000001", `Message ${i}`);
    await Promise.all([file.vider(), autreServeur.vider()]);
    expect(passerelle.envoyes.map((e) => e.texte).sort()).toEqual([0, 1, 2, 3, 4].map((i) => `Message ${i}`));
  });

  it("envoi réservé par un serveur qui s'est arrêté en route : repris après 5 minutes", async () => {
    await file.mettreEnFile("a", "+237600000001", "Bonjour");
    await base.requete("UPDATE sms.envois SET statut = 'en_cours', reserve_le = now() - interval '4 minutes'");
    await file.vider();
    expect(passerelle.envoyes).toHaveLength(0);
    await base.requete("UPDATE sms.envois SET reserve_le = now() - interval '6 minutes'");
    await file.vider();
    expect(passerelle.envoyes).toHaveLength(1);
  });
});
