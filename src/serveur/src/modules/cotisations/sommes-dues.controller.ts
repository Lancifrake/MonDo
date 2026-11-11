import { Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaPaiement } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { SommesDuesService } from "./sommes-dues.service.js";

/** Frais du modèle A, remises et remboursements : créés par le serveur, jamais à la main. */
@Controller()
export class SommesDuesController {
  constructor(@Inject(SommesDuesService) private readonly sommes: SommesDuesService) {}

  @Get("sommes-dues")
  lister(@MembreAuthentifie() membreId: string, @Query("cercleId") cercleId?: string) {
    return this.sommes.listerPour(membreId, typeof cercleId === "string" ? cercleId : undefined);
  }

  @Post("sommes-dues/:id/paiement")
  declarer(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaPaiement)) corps: (typeof schemaPaiement)["_output"],
  ) {
    return this.sommes.declarerPaiement(id, corps.referenceTransaction, membreId);
  }

  @Post("sommes-dues/:id/confirmation")
  confirmer(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.sommes.confirmer(id, membreId);
  }

  /** Parts de MonDo déclarées, à confirmer par un Administrateur après vérification du compte marchand. */
  @Get("administration/sommes-dues")
  aConfirmer(@MembreAuthentifie() membreId: string) {
    return this.sommes.listerPourAdministrateur(membreId);
  }
}
