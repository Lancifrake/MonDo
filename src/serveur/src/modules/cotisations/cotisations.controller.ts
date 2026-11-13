import { BadRequestException, Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaPaiement, schemaPaiementSimule } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { CotisationsService } from "./cotisations.service.js";
import { PaiementsSimulesService } from "./paiements-simules.service.js";

/** Les cotisations ne se créent pas à la main : elles sont générées quand le cercle est complet. */
@Controller("cotisations")
export class CotisationsController {
  constructor(
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(PaiementsSimulesService) private readonly paiements: PaiementsSimulesService,
  ) {}

  @Get()
  lister(@MembreAuthentifie() membreId: string, @Query("cercleId") cercleId?: string) {
    if (!cercleId) throw new BadRequestException("Préciser le cercle (cercleId)");
    return this.cotisations.listerDuMembre(cercleId, membreId);
  }

  /** Qui a payé, qui n'a pas payé, tour par tour, pour tout le cercle (US17). */
  @Get("cercles/:cercleId/etat")
  etat(@Param("cercleId") cercleId: string, @MembreAuthentifie() membreId: string) {
    return this.cotisations.etatDuCercle(cercleId, membreId);
  }

  /** Paiement Mobile Money simulé (M4), hors production : issue réussie, échouée ou en retard. */
  @Post(":id/paiement-simule")
  payerSimule(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaPaiementSimule)) corps: (typeof schemaPaiementSimule)["_output"],
  ) {
    return this.paiements.payer(id, membreId, corps.operateur, corps.issue);
  }

  @Get(":id/paiements-simules")
  paiementsSimules(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.paiements.lister(id, membreId);
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
