import { createHash } from "node:crypto";

export const hacher = (donnee: string | Buffer): string => createHash("sha256").update(donnee).digest("hex");

// Séparation des domaines : un nœud interne ne peut jamais être pris pour une feuille.
const PREFIXE_FEUILLE = Buffer.from([0x00]);
const PREFIXE_NOEUD = Buffer.from([0x01]);

const noeudFeuille = (empreinte: string): string =>
  hacher(Buffer.concat([PREFIXE_FEUILLE, Buffer.from(empreinte, "hex")]));
const paire = (g: string, d: string): string =>
  hacher(Buffer.concat([PREFIXE_NOEUD, Buffer.from(g, "hex"), Buffer.from(d, "hex")]));

export interface EtapePreuve {
  frere: string;
  /** Position du frère par rapport au nœud courant. */
  cote: "gauche" | "droite";
}

/**
 * Arbre de hachage : une seule racine par lot est inscrite sur la chaîne (décision 02, règle 6).
 * Un nœud sans frère est remonté tel quel (jamais dupliqué), sinon [a,b,c] et [a,b,c,c] auraient la même racine.
 */
export function construireArbre(feuilles: readonly string[]): string[][] {
  if (feuilles.length === 0) throw new Error("Un lot ne peut pas être vide");
  const niveaux: string[][] = [feuilles.map(noeudFeuille)];
  while (niveaux[niveaux.length - 1]!.length > 1) {
    const courant = niveaux[niveaux.length - 1]!;
    const suivant: string[] = [];
    for (let i = 0; i < courant.length; i += 2) {
      const droite = courant[i + 1];
      suivant.push(droite === undefined ? courant[i]! : paire(courant[i]!, droite));
    }
    niveaux.push(suivant);
  }
  return niveaux;
}

export const racine = (feuilles: readonly string[]): string => {
  const n = construireArbre(feuilles);
  return n[n.length - 1]![0]!;
};

export function preuve(feuilles: readonly string[], index: number): EtapePreuve[] {
  if (index < 0 || index >= feuilles.length) throw new Error("Index hors du lot");
  const niveaux = construireArbre(feuilles);
  const etapes: EtapePreuve[] = [];
  let i = index;
  for (const niveau of niveaux.slice(0, -1)) {
    const estGauche = i % 2 === 0;
    const frere = niveau[estGauche ? i + 1 : i - 1];
    if (frere !== undefined) etapes.push({ frere, cote: estGauche ? "droite" : "gauche" });
    i = Math.floor(i / 2);
  }
  return etapes;
}

export function verifierPreuve(feuille: string, etapes: readonly EtapePreuve[], racineAttendue: string): boolean {
  let courant = noeudFeuille(feuille);
  for (const { frere, cote } of etapes) {
    courant = cote === "droite" ? paire(courant, frere) : paire(frere, courant);
  }
  return courant === racineAttendue;
}
