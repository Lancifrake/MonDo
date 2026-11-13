import { Body, Controller, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaAvanceDemonstration } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { DemonstrationService } from "./demonstration.service.js";

/** Outils de démonstration : refusés en production, réservés à l'organisateur du cercle (contrôlé par le service). */
@Controller("demonstration/cercles/:cercleId")
export class DemonstrationController {
  constructor(@Inject(DemonstrationService) private readonly demonstration: DemonstrationService) {}

  @Post("membres-fictifs")
  remplir(@Param("cercleId") cercleId: string, @MembreAuthentifie() membreId: string) {
    return this.demonstration.remplir(cercleId, membreId);
  }

  @Post("suite")
  suite(@Param("cercleId") cercleId: string, @MembreAuthentifie() membreId: string) {
    return this.demonstration.jouerLaSuite(cercleId, membreId);
  }

  @Post("avance")
  avancer(
    @Param("cercleId") cercleId: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaAvanceDemonstration)) corps: (typeof schemaAvanceDemonstration)["_output"],
  ) {
    return this.demonstration.avancer(cercleId, membreId, corps.jours);
  }
}
