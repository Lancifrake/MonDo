import { Module } from "@nestjs/common";
import { AdministrationController } from "./administration.controller.js";
import { AdministrationService } from "./administration.service.js";

/** Lecture d'ensemble réservée à l'Administrateur (comptes, cercles). Les décisions vivent dans leurs modules. */
@Module({ controllers: [AdministrationController], providers: [AdministrationService] })
export class AdministrationModule {}
