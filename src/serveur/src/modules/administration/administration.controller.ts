import { Controller, Get, Inject } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { AdministrationService } from "./administration.service.js";

/** Vue d'ensemble pour l'Administrateur : tous les comptes et tous les cercles, en lecture seule. */
@Controller("administration")
export class AdministrationController {
  constructor(@Inject(AdministrationService) private readonly administration: AdministrationService) {}

  @Get("comptes")
  comptes(@MembreAuthentifie() membreId: string) {
    return this.administration.listerComptes(membreId);
  }

  @Get("cercles")
  cercles(@MembreAuthentifie() membreId: string) {
    return this.administration.listerCercles(membreId);
  }
}
