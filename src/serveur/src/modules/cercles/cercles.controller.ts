import { BadRequestException, Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaAdhesion, schemaCreationCercle, schemaInvitation } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { calculerBareme } from "../../score/frais.js";
import { CerclesService } from "./cercles.service.js";

@Controller("cercles")
export class CerclesController {
  constructor(@Inject(CerclesService) private readonly cercles: CerclesService) {}

  @Post()
  creer(
    @MembreAuthentifie() organisateurId: string,
    @Body(new ValidationSchema(schemaCreationCercle)) corps: (typeof schemaCreationCercle)["_output"],
  ) {
    return this.cercles.creer({ organisateurId, ...corps });
  }

  /** Mes cercles, pour l'application : un résumé par cercle, sans la liste des membres. */
  @Get()
  mesCercles(@MembreAuthentifie() membreId: string) {
    return this.cercles.listerPour(membreId);
  }

  /** Barème des frais à écrire dans le règlement avant de le signer (modèle A, décision 05). */
  @Get("bareme")
  bareme(@Query("nombreMembres") nombreMembres: string, @Query("montant") montant: string) {
    const [n, m] = [Number(nombreMembres), Number(montant)];
    if (!Number.isInteger(n) || n < 3 || n > 50 || !Number.isInteger(m) || m <= 0 || m > 100_000_000) {
      throw new BadRequestException("Préciser nombreMembres (3 à 50) et montant (entier positif)");
    }
    return calculerBareme(n, m);
  }

  /** Cercles ouverts qui cherchent des membres, filtrés (US7). */
  @Get("catalogue")
  catalogue(
    @MembreAuthentifie() membreId: string,
    @Query("montantMin") montantMin?: string,
    @Query("montantMax") montantMax?: string,
    @Query("frequence") frequence?: string,
    @Query("nombreMembresMax") nombreMembresMax?: string,
  ) {
    const entier = (v: string | undefined, nom: string) => {
      if (v === undefined) return undefined;
      const n = Number(v);
      if (!Number.isInteger(n) || n < 0 || n > 100_000_000)
        throw new BadRequestException(`${nom} : entier positif attendu`);
      return n;
    };
    if (frequence !== undefined && !["hebdomadaire", "mensuelle", "jours"].includes(frequence)) {
      throw new BadRequestException("frequence : hebdomadaire, mensuelle ou jours");
    }
    return this.cercles.catalogue(membreId, {
      montantMin: entier(montantMin, "montantMin"),
      montantMax: entier(montantMax, "montantMax"),
      nombreMembresMax: entier(nombreMembresMax, "nombreMembresMax"),
      ...(frequence ? { frequence } : {}),
    });
  }

  /** Invitation par numéro, envoyée par SMS (US4). Organisateur seulement. */
  @Post(":id/invitations")
  inviter(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaInvitation)) corps: (typeof schemaInvitation)["_output"],
  ) {
    return this.cercles.inviter(id, membreId, corps.numero);
  }

  @Post(":id/adhesions")
  rejoindre(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaAdhesion)) corps: (typeof schemaAdhesion)["_output"],
  ) {
    return this.cercles.rejoindre(id, { membreId, placeSouhaitee: corps.placeSouhaitee, signature: corps.signature });
  }

  /** Quitter un cercle en cours de cycle, avant d'avoir reçu sa cagnotte (score −15). */
  @Post(":id/depart")
  quitter(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.cercles.quitter(id, membreId);
  }

  /** Registre du cercle et vérification d'intégrité, pour ses membres (cahier des charges, M10). */
  @Get(":id/registre")
  registre(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.cercles.registreDuCercle(id, membreId);
  }

  @Get(":id")
  consulter(@Param("id") id: string, @MembreAuthentifie() demandeurId: string) {
    return this.cercles.consulterPour(id, demandeurId);
  }
}
