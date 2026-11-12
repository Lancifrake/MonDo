import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaDecisionLitige, schemaOuvertureLitige } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { LitigesService } from "./litiges.service.js";

@Controller("litiges")
export class LitigesController {
  constructor(@Inject(LitigesService) private readonly litiges: LitigesService) {}

  @Post()
  ouvrir(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaOuvertureLitige)) corps: (typeof schemaOuvertureLitige)["_output"],
  ) {
    return this.litiges.ouvrir(corps.cotisationId, corps.motif, membreId);
  }

  /** Litiges ouverts, pour l'administrateur. */
  @Get()
  lister(@MembreAuthentifie() membreId: string) {
    return this.litiges.listerOuverts(membreId);
  }

  /** Mes litiges, ouverts ou non, pour l'application : ceux où je suis payeur ou bénéficiaire. */
  @Get("miens")
  miens(@MembreAuthentifie() membreId: string) {
    return this.litiges.listerPour(membreId);
  }

  @Get(":id")
  consulter(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.litiges.consulter(id, membreId);
  }

  @Post(":id/decision")
  trancher(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaDecisionLitige)) corps: (typeof schemaDecisionLitige)["_output"],
  ) {
    return this.litiges.trancher(id, corps.decision, corps.motif, membreId);
  }
}
