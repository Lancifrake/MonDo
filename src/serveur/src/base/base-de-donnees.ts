export const BASE_DE_DONNEES = Symbol("BASE_DE_DONNEES");

export type Ligne = Record<string, unknown>;

export interface Executeur {
  requete<T extends Ligne = Ligne>(sql: string, parametres?: unknown[]): Promise<T[]>;
}

/** Accès à PostgreSQL. Chaque module n'interroge que son propre schéma (décision 02, règle 1). */
export interface BaseDeDonnees extends Executeur {
  transaction<T>(travail: (tx: Executeur) => Promise<T>): Promise<T>;
  /** Plusieurs instructions sans paramètres (migrations). */
  executerScript(sql: string): Promise<void>;
  fermer(): Promise<void>;
}

/** Code PostgreSQL d'une violation d'unicité. */
export const estDoublon = (e: unknown): boolean => (e as { code?: unknown })?.code === "23505";
