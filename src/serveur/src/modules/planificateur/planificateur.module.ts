import { Module } from "@nestjs/common";
import { PlanificateurService } from "./planificateur.service.js";

@Module({ providers: [PlanificateurService], exports: [PlanificateurService] })
export class PlanificateurModule {}
