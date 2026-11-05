import { Module } from "@nestjs/common";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { DeclencheurPlanificateur } from "./declencheur.js";
import { PlanificateurService } from "./planificateur.service.js";

@Module({
  imports: [CotisationsModule],
  providers: [PlanificateurService, DeclencheurPlanificateur],
  exports: [PlanificateurService, DeclencheurPlanificateur],
})
export class PlanificateurModule {}
