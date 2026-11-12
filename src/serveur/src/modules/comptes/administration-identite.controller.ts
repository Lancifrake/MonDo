import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaDecisionIdentite } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { IdentiteService } from "./identite.service.js";

/** File d'attente des vérifications d'identité. Chaque méthode du service exige un Administrateur. */
@Controller("administration/identites")
export class AdministrationIdentiteController {
  constructor(@Inject(IdentiteService) private readonly identite: IdentiteService) {}

  @Get()
  enAttente(@MembreAuthentifie() membreId: string) {
    return this.identite.listerEnAttente(membreId);
  }

  @Get(":id/pieces/:nature")
  piece(@Param("id") id: string, @Param("nature") nature: string, @MembreAuthentifie() membreId: string) {
    return this.identite.lirePiece(id, nature, membreId);
  }

  @Post(":id/decision")
  decider(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaDecisionIdentite)) corps: (typeof schemaDecisionIdentite)["_output"],
  ) {
    return this.identite.decider(id, corps.decision, corps.motif, membreId);
  }
}
