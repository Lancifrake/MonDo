import { Global, Inject, Logger, Module, type OnApplicationShutdown } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "./base-de-donnees.js";
import { migrer } from "./migrations.js";
import { BaseDeDonneesPglite } from "./pglite.js";
import { BaseDeDonneesPostgres } from "./postgres.js";

async function ouvrirBase(): Promise<BaseDeDonnees> {
  const url = process.env.DATABASE_URL;
  if (!url) new Logger("Base").warn("DATABASE_URL absente : PostgreSQL embarqué en mémoire, données perdues à l'arrêt");
  const base = url ? new BaseDeDonneesPostgres(url) : await BaseDeDonneesPglite.creer();
  await migrer(base);
  return base;
}

@Global()
@Module({
  providers: [{ provide: BASE_DE_DONNEES, useFactory: ouvrirBase }],
  exports: [BASE_DE_DONNEES],
})
export class BaseModule implements OnApplicationShutdown {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  onApplicationShutdown(): Promise<void> {
    return this.base.fermer();
  }
}
