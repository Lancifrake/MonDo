import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module.js";
import { DeclencheurPlanificateur, intervallePlanificateur } from "./modules/planificateur/declencheur.js";

async function demarrer() {
  const intervalle = intervallePlanificateur(process.env);
  const app = await NestFactory.create(AppModule);
  // Arrêt propre (SIGTERM) : le passage en cours du planificateur se termine avant la fermeture de la base.
  app.enableShutdownHooks();
  await app.listen(Number(process.env.PORT ?? 3000));
  if (intervalle) app.get(DeclencheurPlanificateur).demarrer(intervalle);
}

void demarrer();
