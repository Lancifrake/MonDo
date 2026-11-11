import { Body, Controller, ForbiddenException, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie, Public } from "../../authentification/garde.js";
import {
  schemaAccordContact,
  schemaContactConfiance,
  schemaDemandeOtp,
  schemaInscription,
} from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { OtpService } from "./otp.service.js";

@Controller("comptes")
export class ComptesController {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(OtpService) private readonly otp: OtpService,
    @Inject(ContactConfianceService) private readonly contacts: ContactConfianceService,
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

  /** Contact de confiance : chacun ne gère que le sien, l'identité vient de la signature. */
  @Get("moi/contact-de-confiance")
  contact(@MembreAuthentifie() membreId: string) {
    return this.contacts.consulter(membreId);
  }

  @Post("moi/contact-de-confiance")
  designerContact(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaContactConfiance)) corps: (typeof schemaContactConfiance)["_output"],
  ) {
    return this.contacts.designer(membreId, corps);
  }

  @Post("moi/contact-de-confiance/accord")
  accordContact(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaAccordContact)) corps: (typeof schemaAccordContact)["_output"],
  ) {
    return this.contacts.enregistrerAccord(membreId, corps.code);
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
