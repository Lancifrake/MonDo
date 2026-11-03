import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { CerclesService, type Reglement } from "./cercles.service.js";

@Controller("cercles")
export class CerclesController {
  constructor(@Inject(CerclesService) private readonly cercles: CerclesService) {}

  @Post()
  creer(@Body() corps: { organisateurId: string; reglement: Reglement; signature: string }) {
    return this.cercles.creer(corps);
  }

  @Post(":id/adhesions")
  rejoindre(@Param("id") id: string, @Body() corps: { membreId: string; signature: string }) {
    return this.cercles.rejoindre(id, corps);
  }

  @Get(":id")
  consulter(@Param("id") id: string) {
    return this.cercles.trouver(id);
  }
}
