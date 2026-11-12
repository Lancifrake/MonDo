import { Logger } from "@nestjs/common";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "node:crypto";
import { mkdirSync, mkdtempSync } from "node:fs";
import { readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

export const STOCKAGE_OBJETS = Symbol("STOCKAGE_OBJETS");

/**
 * Stockage des fichiers sensibles (pièces d'identité), hors de la base (décision 02, règle 7 ; SECURITY.md,
 * règle 7). Un vrai stockage d'objets chiffré viendra derrière cette interface avec l'hébergeur.
 */
export interface StockageObjets {
  deposer(cle: string, contenu: Buffer): Promise<void>;
  lire(cle: string): Promise<Buffer>;
  /** Sans effet si l'objet n'existe plus : une suppression se rejoue sans erreur. */
  supprimer(cle: string): Promise<void>;
}

/**
 * Implémentation du prototype : un fichier par objet, chiffré en AES-256-GCM. Fichier = nonce (12 octets),
 * sceau (16 octets), contenu chiffré. Le nom de l'objet est lié au chiffrement : un fichier modifié, déplacé
 * ou lu avec une autre clé est refusé. Le nom du fichier est une empreinte, il ne dit rien de l'objet.
 */
export class StockageLocalChiffre implements StockageObjets {
  constructor(
    private readonly dossier: string,
    private readonly cleChiffrement: Buffer,
  ) {
    if (cleChiffrement.length !== 32) throw new Error("Clé de stockage invalide : 32 octets attendus");
    mkdirSync(dossier, { recursive: true, mode: 0o700 });
  }

  private chemin(cle: string): string {
    return join(this.dossier, createHash("sha256").update(cle).digest("hex"));
  }

  async deposer(cle: string, contenu: Buffer): Promise<void> {
    const nonce = randomBytes(12);
    const chiffre = createCipheriv("aes-256-gcm", this.cleChiffrement, nonce);
    chiffre.setAAD(Buffer.from(cle));
    const corps = Buffer.concat([chiffre.update(contenu), chiffre.final()]);
    await writeFile(this.chemin(cle), Buffer.concat([nonce, chiffre.getAuthTag(), corps]), { mode: 0o600 });
  }

  async lire(cle: string): Promise<Buffer> {
    const brut = await readFile(this.chemin(cle));
    const dechiffre = createDecipheriv("aes-256-gcm", this.cleChiffrement, brut.subarray(0, 12));
    dechiffre.setAAD(Buffer.from(cle));
    dechiffre.setAuthTag(brut.subarray(12, 28));
    return Buffer.concat([dechiffre.update(brut.subarray(28)), dechiffre.final()]);
  }

  async supprimer(cle: string): Promise<void> {
    await rm(this.chemin(cle), { force: true });
  }
}

/**
 * `MONDO_STOCKAGE_CLE` (32 octets en base64) et `MONDO_STOCKAGE_DOSSIER` : stockage chiffré persistant.
 * Sans eux, hors production : clé tirée au hasard et dossier temporaire, perdus à l'arrêt (développement et tests).
 * En production, démarrage refusé sans les deux : jamais de pièce d'identité sous une clé jetable.
 */
export function creerStockage(env: NodeJS.ProcessEnv = process.env): StockageObjets {
  const { MONDO_STOCKAGE_CLE: cle, MONDO_STOCKAGE_DOSSIER: dossier } = env;
  if (cle && dossier) return new StockageLocalChiffre(dossier, Buffer.from(cle, "base64"));
  if (env.NODE_ENV === "production") {
    throw new Error(
      "Stockage des pièces non configuré, interdit en production : définir MONDO_STOCKAGE_CLE et MONDO_STOCKAGE_DOSSIER",
    );
  }
  new Logger("Stockage").warn("Stockage des pièces éphémère : clé et dossier temporaires, perdus à l'arrêt");
  return new StockageLocalChiffre(mkdtempSync(join(tmpdir(), "mondo-stockage-")), randomBytes(32));
}
