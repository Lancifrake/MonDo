import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaAdhesion, schemaCreationCercle } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
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
