import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaAcceptationEchange, schemaPropositionEchange } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { EchangesService } from "./echanges.service.js";

/** Échange de places entre deux membres d'un cercle complet. Le service contrôle qui a le droit de quoi. */
@Controller("cercles/:cercleId/echanges")
export class EchangesController {
  constructor(@Inject(EchangesService) private readonly echanges: EchangesService) {}

  @Get()
  lister(@Param("cercleId") cercleId: string, @MembreAuthentifie() membreId: string) {
    return this.echanges.listerPour(cercleId, membreId);
  }

  @Post()
  proposer(
    @Param("cercleId") cercleId: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaPropositionEchange)) corps: (typeof schemaPropositionEchange)["_output"],
  ) {
    return this.echanges.proposer(cercleId, membreId, corps);
  }

  @Post(":id/acceptation")
  accepter(
    @Param("cercleId") cercleId: string,
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaAcceptationEchange)) corps: (typeof schemaAcceptationEchange)["_output"],
  ) {
    return this.echanges.accepter(cercleId, id, membreId, corps.signature);
  }

  @Post(":id/refus")
  refuser(@Param("cercleId") cercleId: string, @Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.echanges.refuser(cercleId, id, membreId);
  }
}
