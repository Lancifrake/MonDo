import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaDecisionRecuperation } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { RecuperationService } from "./recuperation.service.js";

/** Récupérations contestées par le titulaire. Chaque méthode du service exige un Administrateur. */
@Controller("administration/recuperations")
export class AdministrationRecuperationController {
  constructor(@Inject(RecuperationService) private readonly recuperation: RecuperationService) {}

  @Get()
  opposees(@MembreAuthentifie() membreId: string) {
    return this.recuperation.listerOpposees(membreId);
  }

  @Post(":id/decision")
  trancher(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaDecisionRecuperation)) corps: (typeof schemaDecisionRecuperation)["_output"],
  ) {
    return this.recuperation.trancher(id, corps.decision, corps.motif, membreId);
  }
}
