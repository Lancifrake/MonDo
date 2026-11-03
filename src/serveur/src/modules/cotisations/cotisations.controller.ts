import { Body, Controller, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaCreationCotisation, schemaPaiement } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { CotisationsService } from "./cotisations.service.js";

@Controller("cotisations")
export class CotisationsController {
  constructor(@Inject(CotisationsService) private readonly cotisations: CotisationsService) {}

  /** Prototype : le payeur ouvre sa cotisation. Plus tard, le module Cercles la créera à chaque tour. */
  @Post()
  creer(
    @MembreAuthentifie() payeurId: string,
    @Body(new ValidationSchema(schemaCreationCotisation)) corps: (typeof schemaCreationCotisation)["_output"],
  ) {
    return this.cotisations.creer({ payeurId, ...corps });
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
