import { Controller, Get, Inject, Param } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { PreuveService } from "./preuve.service.js";

@Controller("preuve")
export class PreuveController {
  constructor(@Inject(PreuveService) private readonly preuve: PreuveService) {}

  @Get("cercles/:cercleId/membres/:membreId/dossier")
  dossier(
    @Param("cercleId") cercleId: string,
    @Param("membreId") debiteurId: string,
    @MembreAuthentifie() demandeurId: string,
  ) {
    return this.preuve.exporterDossier(cercleId, debiteurId, demandeurId);
  }
}
