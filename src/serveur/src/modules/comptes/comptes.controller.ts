import { Body, Controller, Inject, Param, Post } from "@nestjs/common";
import { ComptesService } from "./comptes.service.js";

@Controller("comptes")
export class ComptesController {
  constructor(@Inject(ComptesService) private readonly comptes: ComptesService) {}

  @Post()
  inscrire(@Body() corps: { numero: string; nom: string; clePublique: JsonWebKey }) {
    return this.comptes.inscrire(corps);
  }

  @Post(":id/niveau2")
  niveau2(@Param("id") id: string) {
    return this.comptes.passerAuNiveau2(id);
  }
}
