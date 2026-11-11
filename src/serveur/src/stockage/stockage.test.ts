import { mkdtempSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { randomBytes } from "node:crypto";
import { describe, expect, it } from "vitest";
import { StockageLocalChiffre, creerStockage } from "./stockage-objets.js";

const dossier = () => mkdtempSync(join(tmpdir(), "mondo-stockage-test-"));
const cle = () => randomBytes(32);

describe("stockage d'objets local chiffré", () => {
  it("rend ce qu'on a déposé, et rien n'est lisible en clair sur le disque", async () => {
    const d = dossier();
    const s = new StockageLocalChiffre(d, cle());
    const contenu = Buffer.from("image fictive de test, jamais une vraie pièce".repeat(20));
    await s.deposer("identite/abc/recto", contenu);
    expect((await s.lire("identite/abc/recto")).equals(contenu)).toBe(true);
    const fichiers = readdirSync(d);
    expect(fichiers).toHaveLength(1);
    // Ni le nom ni le contenu ne révèlent quoi que ce soit.
    expect(fichiers[0]).not.toContain("recto");
    expect(readFileSync(join(d, fichiers[0]!)).includes(Buffer.from("image fictive"))).toBe(false);
  });

  it("refuse un fichier modifié, une mauvaise clé, et un objet déplacé sous un autre nom", async () => {
    const d = dossier();
    const k = cle();
    const s = new StockageLocalChiffre(d, k);
    await s.deposer("a", Buffer.from("contenu"));
    await s.deposer("b", Buffer.from("autre"));
    const [fa, fb] = readdirSync(d).map((f) => join(d, f));
    await expect(new StockageLocalChiffre(d, cle()).lire("a")).rejects.toThrow();
    // Échanger deux fichiers : le nom de l'objet est lié au chiffrement.
    const [ca, cb] = [readFileSync(fa!), readFileSync(fb!)];
    writeFileSync(fa!, cb);
    writeFileSync(fb!, ca);
    await expect(s.lire("a")).rejects.toThrow();
    const abime = Buffer.from(ca);
    abime[abime.length - 1]! ^= 1;
    writeFileSync(fb!, abime);
    await expect(s.lire("b")).rejects.toThrow();
  });

  it("supprimer efface le fichier ; supprimer deux fois ne casse rien ; lire ensuite échoue", async () => {
    const d = dossier();
    const s = new StockageLocalChiffre(d, cle());
    await s.deposer("x", Buffer.from("1"));
    await s.supprimer("x");
    await s.supprimer("x");
    expect(readdirSync(d)).toHaveLength(0);
    await expect(s.lire("x")).rejects.toThrow();
  });

  it("exige une clé de 32 octets", () => {
    expect(() => new StockageLocalChiffre(dossier(), randomBytes(16))).toThrow(/32 octets/);
  });
});

describe("configuration du stockage", () => {
  it("hors production, sans configuration : clé éphémère et dossier temporaire", async () => {
    const s = creerStockage({});
    await s.deposer("essai", Buffer.from("ok"));
    expect((await s.lire("essai")).toString()).toBe("ok");
    await s.supprimer("essai");
  });

  it("en production : refuse de démarrer sans clé et sans dossier explicites", () => {
    expect(() => creerStockage({ NODE_ENV: "production" })).toThrow(/production/);
    expect(() => creerStockage({ NODE_ENV: "production", MONDO_STOCKAGE_CLE: cle().toString("base64") })).toThrow(
      /production/,
    );
  });

  it("avec clé et dossier : stockage persistant, relisible par une autre instance", async () => {
    const env = {
      NODE_ENV: "production",
      MONDO_STOCKAGE_CLE: cle().toString("base64"),
      MONDO_STOCKAGE_DOSSIER: dossier(),
    };
    await creerStockage(env).deposer("p", Buffer.from("durable"));
    expect((await creerStockage(env).lire("p")).toString()).toBe("durable");
  });

  it("refuse une clé mal formée", () => {
    expect(() => creerStockage({ MONDO_STOCKAGE_CLE: "trop-courte", MONDO_STOCKAGE_DOSSIER: dossier() })).toThrow(
      /32 octets/,
    );
  });
});
