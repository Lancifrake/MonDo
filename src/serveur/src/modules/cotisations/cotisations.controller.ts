import { BadRequestException, Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaPaiement } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { CotisationsService } from "./cotisations.service.js";

/** Les cotisations ne se créent pas à la main : elles sont générées quand le cercle est complet. */
@Controller("cotisations")
export class CotisationsController {
  constructor(@Inject(CotisationsService) private readonly cotisations: CotisationsService) {}

  @Get()
  lister(@MembreAuthentifie() membreId: string, @Query("cercleId") cercleId?: string) {
    if (!cercleId) throw new BadRequestException("Préciser le cercle (cercleId)");
    return this.cotisations.listerDuMembre(cercleId, membreId);
  }

  @Post(":id/paiement")
  declarer(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaPaiement)) corps: (typeof schemaPaiement)["_output"],
  ) {
    return this.cotisations.declarerPaiement(id, corps.referenceTransaction, membreId);
  }

  @Post(":id/confirmation")
  confirmer(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.cotisations.confirmer(id, membreId);
  }
}
