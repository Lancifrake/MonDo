import { PGlite } from "@electric-sql/pglite";
import type { BaseDeDonnees, Executeur, Ligne } from "./base-de-donnees.js";

/** PostgreSQL embarqué (WebAssembly), sans serveur : tests et développement local. Données perdues à l'arrêt. */
export class BaseDeDonneesPglite implements BaseDeDonnees {
  private constructor(private readonly db: PGlite) {}

  static async creer(): Promise<BaseDeDonneesPglite> {
    return new BaseDeDonneesPglite(await PGlite.create());
  }

  async requete<T extends Ligne = Ligne>(sql: string, parametres: unknown[] = []): Promise<T[]> {
    return (await this.db.query<T>(sql, parametres)).rows;
  }

  transaction<T>(travail: (tx: Executeur) => Promise<T>): Promise<T> {
    return this.db.transaction((tx) =>
      travail({
        requete: async <U extends Ligne = Ligne>(sql: string, parametres: unknown[] = []) =>
          (await tx.query<U>(sql, parametres)).rows,
      }),
    );
  }

  async executerScript(sql: string): Promise<void> {
    await this.db.exec(sql);
  }

  fermer(): Promise<void> {
    return this.db.close();
  }
}
