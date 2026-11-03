import { Module } from "@nestjs/common";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { PlanificateurService } from "./planificateur.service.js";

@Module({ imports: [CotisationsModule], providers: [PlanificateurService], exports: [PlanificateurService] })
export class PlanificateurModule {}
