import { BadRequestException, Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaAdhesion, schemaCreationCercle } from "../../validation/schemas.js";
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

  @Post(":id/adhesions")
  rejoindre(
    @Param("id") id: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaAdhesion)) corps: (typeof schemaAdhesion)["_output"],
  ) {
    return this.cercles.rejoindre(id, { membreId, placeSouhaitee: corps.placeSouhaitee, signature: corps.signature });
  }

  @Get(":id")
  consulter(@Param("id") id: string, @MembreAuthentifie() demandeurId: string) {
    return this.cercles.consulterPour(id, demandeurId);
  }
}
