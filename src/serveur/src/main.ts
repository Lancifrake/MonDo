import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import type { NestExpressApplication } from "@nestjs/platform-express";
import { AppModule } from "./app.module.js";
import { DeclencheurPlanificateur, intervallePlanificateur } from "./modules/planificateur/declencheur.js";

async function demarrer() {
  const intervalle = intervallePlanificateur(process.env);
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // Ne pas annoncer le framework (en-tête « X-Powered-By: Express ») : rien à offrir à un attaquant.
  app.disable("x-powered-by");
  // Arrêt propre (SIGTERM) : le passage en cours du planificateur se termine avant la fermeture de la base.
  app.enableShutdownHooks();
  await app.listen(Number(process.env.PORT ?? 3000));
  if (intervalle) app.get(DeclencheurPlanificateur).demarrer(intervalle);
}

void demarrer();
