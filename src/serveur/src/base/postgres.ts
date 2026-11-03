import pg from "pg";
import type { BaseDeDonnees, Executeur, Ligne } from "./base-de-donnees.js";

/** Vrai serveur PostgreSQL (Supabase ou autre), via DATABASE_URL. */
export class BaseDeDonneesPostgres implements BaseDeDonnees {
  private readonly pool: pg.Pool;

  constructor(url: string) {
    this.pool = new pg.Pool({ connectionString: url });
  }

  async requete<T extends Ligne = Ligne>(sql: string, parametres: unknown[] = []): Promise<T[]> {
    return (await this.pool.query(sql, parametres)).rows as T[];
  }

  async transaction<T>(travail: (tx: Executeur) => Promise<T>): Promise<T> {
    const connexion = await this.pool.connect();
    try {
      await connexion.query("BEGIN");
      const resultat = await travail({
        requete: async <U extends Ligne = Ligne>(sql: string, parametres: unknown[] = []) =>
          (await connexion.query(sql, parametres)).rows as U[],
      });
      await connexion.query("COMMIT");
      return resultat;
    } catch (e) {
      await connexion.query("ROLLBACK");
      throw e;
    } finally {
      connexion.release();
    }
  }

  async executerScript(sql: string): Promise<void> {
    await this.pool.query(sql);
  }

  fermer(): Promise<void> {
    return this.pool.end();
  }
}
