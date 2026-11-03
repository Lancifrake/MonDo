import { createHash } from "node:crypto";

export const hacher = (donnee: string | Buffer): string => createHash("sha256").update(donnee).digest("hex");

const paire = (g: string, d: string): string => hacher(Buffer.from(g + d, "hex"));

export interface EtapePreuve {
  frere: string;
  /** Position du frère par rapport au nœud courant. */
  cote: "gauche" | "droite";
}

/** Arbre de hachage : une seule racine par lot est inscrite sur la chaîne (décision 02, règle 6). */
export function construireArbre(feuilles: readonly string[]): string[][] {
  if (feuilles.length === 0) throw new Error("Un lot ne peut pas être vide");
  const niveaux: string[][] = [[...feuilles]];
  while (niveaux[niveaux.length - 1]!.length > 1) {
    const courant = niveaux[niveaux.length - 1]!;
    const suivant: string[] = [];
    for (let i = 0; i < courant.length; i += 2) {
      const g = courant[i]!;
      suivant.push(paire(g, courant[i + 1] ?? g)); // dernier nœud impair : dupliqué
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
    const frere = niveau[estGauche ? i + 1 : i - 1] ?? niveau[i]!;
    etapes.push({ frere, cote: estGauche ? "droite" : "gauche" });
    i = Math.floor(i / 2);
  }
  return etapes;
}

export function verifierPreuve(feuille: string, etapes: readonly EtapePreuve[], racineAttendue: string): boolean {
  let courant = feuille;
  for (const { frere, cote } of etapes) {
    courant = cote === "droite" ? paire(courant, frere) : paire(frere, courant);
  }
  return courant === racineAttendue;
}
