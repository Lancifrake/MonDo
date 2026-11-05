import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import { DeclencheurPlanificateur } from "./modules/planificateur/declencheur.js";
import { PlanificateurService } from "./modules/planificateur/planificateur.service.js";

let app: INestApplication;

// Démarrage de l'application hors du test, comme les autres fichiers : il peut être lent en CI sous couverture.
beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.init();
});

describe("planificateur dans le vrai serveur", () => {
  it("démarré sur l'application : examine les échéances, et la fermeture attend le passage en cours", async () => {
    const examiner = vi.spyOn(app.get(PlanificateurService), "examinerEcheances");
    app.get(DeclencheurPlanificateur).demarrer(60 * 60 * 1000);
    expect(examiner).toHaveBeenCalledTimes(1);
    await app.close();
    await expect(examiner.mock.results[0]!.value).resolves.toEqual({ traitees: 0, echecs: 0 });
  });
});
