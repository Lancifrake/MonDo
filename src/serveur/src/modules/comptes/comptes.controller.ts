import { Body, Controller, ForbiddenException, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie, Public } from "../../authentification/garde.js";
import {
  schemaAccordContact,
  schemaCodeSecret,
  schemaContactConfiance,
  schemaDemandeRecuperation,
  schemaDemandeOtp,
  schemaDepotIdentite,
  schemaInscription,
  schemaParrainage,
  schemaPiecesRecuperation,
} from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { IdentiteService, TEXTE_CONSENTEMENT, VERSION_CONSENTEMENT } from "./identite.service.js";
import { OtpService } from "./otp.service.js";
import { ParrainagesService } from "./parrainages.service.js";
import { RecuperationService } from "./recuperation.service.js";

@Controller("comptes")
export class ComptesController {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(OtpService) private readonly otp: OtpService,
    @Inject(ContactConfianceService) private readonly contacts: ContactConfianceService,
    @Inject(IdentiteService) private readonly identite: IdentiteService,
    @Inject(RecuperationService) private readonly recuperation: RecuperationService,
    @Inject(ParrainagesService) private readonly parrainages: ParrainagesService,
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

  /** Texte de consentement en vigueur, à afficher avant le dépôt des pièces. */
  @Get("moi/identite/consentement")
  consentement() {
    return { version: VERSION_CONSENTEMENT, texte: TEXTE_CONSENTEMENT };
  }

  /** Mon dossier de vérification d'identité, sans aucune image. */
  @Get("moi/identite")
  monIdentite(@MembreAuthentifie() membreId: string) {
    return this.identite.consulterLeMien(membreId);
  }

  /** Dépôt du recto, du verso et du selfie, avec consentement explicite. Décision par un Administrateur. */
  @Post("moi/identite")
  deposerIdentite(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaDepotIdentite)) corps: (typeof schemaDepotIdentite)["_output"],
  ) {
    return this.identite.deposer(membreId, corps);
  }

  /** Code secret demandé à la récupération du compte (flow 1 et 2). Le redéfinir remplace l'ancien. */
  @Post("moi/code-secret")
  codeSecret(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaCodeSecret)) corps: (typeof schemaCodeSecret)["_output"],
  ) {
    return this.recuperation.definirCodeSecret(membreId, corps.code);
  }

  /**
   * Récupération depuis un nouveau téléphone : sans requête signée, puisque l'ancienne clé est perdue. La
   * demande est prouvée par le code SMS, le code secret et la détention de la nouvelle clé.
   */
  @Public()
  @Post("recuperation")
  demanderRecuperation(
    @Body(new ValidationSchema(schemaDemandeRecuperation)) corps: (typeof schemaDemandeRecuperation)["_output"],
  ) {
    return this.recuperation.demander(corps);
  }

  /** Pièces de la récupération sans contact, prouvées par la nouvelle clé (dans le corps, pas par la garde). */
  @Public()
  @Post("recuperation/:id/pieces")
  piecesRecuperation(
    @Param("id") id: string,
    @Body(new ValidationSchema(schemaPiecesRecuperation)) corps: (typeof schemaPiecesRecuperation)["_output"],
  ) {
    const { consentement: _consentement, ...pieces } = corps;
    return this.recuperation.deposerPieces(id, pieces);
  }

  /** La récupération en cours sur mon compte, vue de l'ancien téléphone. */
  @Get("moi/recuperation")
  maRecuperation(@MembreAuthentifie() membreId: string) {
    return this.recuperation.enCoursPour(membreId);
  }

  /** Le titulaire s'oppose : le compte est bloqué jusqu'à la décision d'un Administrateur. */
  @Post("moi/recuperation/opposition")
  opposition(@MembreAuthentifie() membreId: string) {
    return this.recuperation.sOpposer(membreId);
  }

  /** Parrainage (US6) : proposé par un membre fiable, accepté ou refusé par le filleul. Jamais une caution. */
  @Get("moi/parrainages")
  mesParrainages(@MembreAuthentifie() membreId: string) {
    return this.parrainages.lesMiens(membreId);
  }

  @Post("moi/parrainages")
  proposerParrainage(
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaParrainage)) corps: (typeof schemaParrainage)["_output"],
  ) {
    return this.parrainages.proposer(membreId, corps.filleulId);
  }

  @Post("moi/parrainages/:id/acceptation")
  accepterParrainage(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.parrainages.repondre(id, membreId, "accepte");
  }

  @Post("moi/parrainages/:id/refus")
  refuserParrainage(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.parrainages.repondre(id, membreId, "refuse");
  }

  @Post(":id/niveau2")
  async niveau2(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    if (id !== membreId) throw new ForbiddenException("On ne vérifie que sa propre identité");
    // Raccourci de démonstration et de test : aucune pièce n'est contrôlée. En production, le niveau 2 ne
    // s'obtient que par le dépôt des pièces et la décision d'un Administrateur.
    if (process.env.NODE_ENV === "production") {
      throw new ForbiddenException(
        "Raccourci désactivé en production : déposer ses pièces par POST /comptes/moi/identite (vérification par un administrateur)",
      );
    }
    return this.comptes.passerAuNiveau2(id);
  }
}
