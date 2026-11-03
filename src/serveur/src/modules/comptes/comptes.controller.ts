import { Body, Controller, ForbiddenException, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie, Public } from "../../authentification/garde.js";
import { schemaDemandeOtp, schemaInscription } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { ComptesService } from "./comptes.service.js";
import { OtpService } from "./otp.service.js";

@Controller("comptes")
export class ComptesController {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(OtpService) private readonly otp: OtpService,
  ) {}

  @Public()
  @Post("otp")
  demanderCode(@Body(new ValidationSchema(schemaDemandeOtp)) corps: (typeof schemaDemandeOtp)["_output"]) {
    return this.otp.demander(corps.numero);
  }

  @Public()
  @Post()
  inscrire(@Body(new ValidationSchema(schemaInscription)) corps: (typeof schemaInscription)["_output"]) {
    return this.comptes.inscrire(corps);
  }

  @Post(":id/niveau2")
  async niveau2(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    if (id !== membreId) throw new ForbiddenException("On ne vérifie que sa propre identité");
    return this.comptes.passerAuNiveau2(id);
  }
}
