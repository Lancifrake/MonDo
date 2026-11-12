import { Module } from "@nestjs/common";
import { CerclesModule } from "../cercles/cercles.module.js";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { DeclencheurPlanificateur } from "./declencheur.js";
import { PlanificateurService } from "./planificateur.service.js";

@Module({
  imports: [CotisationsModule, ComptesModule, CerclesModule],
  providers: [PlanificateurService, DeclencheurPlanificateur],
  exports: [PlanificateurService, DeclencheurPlanificateur],
})
export class PlanificateurModule {}
