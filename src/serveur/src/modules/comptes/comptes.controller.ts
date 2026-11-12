import { Body, Controller, ForbiddenException, Get, Inject, Param, Post } from "@nestjs/common";
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

  /** Mon compte, pour l'application. La clé publique ne sert qu'au serveur : elle n'est pas renvoyée. */
  @Get("moi")
  async moi(@MembreAuthentifie() membreId: string) {
    const { clePublique: _clePublique, ...compte } = await this.comptes.trouver(membreId);
    return compte;
  }

  @Post(":id/niveau2")
  async niveau2(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    if (id !== membreId) throw new ForbiddenException("On ne vérifie que sa propre identité");
    // Prototype : aucune pièce n'est contrôlée. En production, personne ne doit pouvoir se déclarer vérifié
    // tant qu'un prestataire de vérification d'identité n'est pas branché (vision, V2).
    if (process.env.NODE_ENV === "production") {
      throw new ForbiddenException(
        "Vérification d'identité simulée, désactivée en production : brancher un prestataire de vérification",
      );
    }
    return this.comptes.passerAuNiveau2(id);
  }
}
