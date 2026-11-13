import { Module } from "@nestjs/common";
import { CerclesModule } from "../cercles/cercles.module.js";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { PlanificateurModule } from "../planificateur/planificateur.module.js";
import { DemonstrationController } from "./demonstration.controller.js";
import { DemonstrationService } from "./demonstration.service.js";

@Module({
  imports: [ComptesModule, CerclesModule, CotisationsModule, PlanificateurModule],
  controllers: [DemonstrationController],
  providers: [DemonstrationService],
})
export class DemonstrationModule {}
