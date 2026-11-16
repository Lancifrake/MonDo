import { Controller, Get, Inject } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { PreuveService } from "./preuve.service.js";

/** Défauts constatés et mises en demeure, en lecture seule pour l'Administrateur. */
@Controller("administration/defauts")
export class AdministrationDefautsController {
  constructor(@Inject(PreuveService) private readonly preuve: PreuveService) {}

  @Get()
  lister(@MembreAuthentifie() membreId: string) {
    return this.preuve.listerPourAdministrateur(membreId);
  }
}
