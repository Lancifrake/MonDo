import { Controller, Get, Inject, Query } from "@nestjs/common";
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

  @Get("tableau-de-bord")
  tableauDeBord(@MembreAuthentifie() membreId: string) {
    return this.administration.tableauDeBord(membreId);
  }

  @Get("journal")
  journal(@MembreAuthentifie() membreId: string, @Query("limite") limite?: string) {
    const n = limite === undefined ? 100 : Number(limite);
    return this.administration.journal(membreId, Number.isInteger(n) && n >= 1 && n <= 500 ? n : 100);
  }

  @Get("registre/verification")
  verificationRegistre(@MembreAuthentifie() membreId: string) {
    return this.administration.verifierRegistre(membreId);
  }

  @Get("sante")
  sante(@MembreAuthentifie() membreId: string) {
    return this.administration.sante(membreId);
  }
}
