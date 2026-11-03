import type { BaseDeDonnees } from "../base/base-de-donnees.js";
import { migrer } from "../base/migrations.js";
import { BaseDeDonneesPglite } from "../base/pglite.js";

/** Base PostgreSQL embarquée, neuve et migrée, propre à un test. */
export async function baseDeTest(): Promise<BaseDeDonnees> {
  const base = await BaseDeDonneesPglite.creer();
  await migrer(base);
  return base;
}
