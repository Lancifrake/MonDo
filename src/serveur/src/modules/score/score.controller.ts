import { Controller, Get, Inject, Param } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { ScoreService } from "./score.service.js";

@Controller("score")
export class ScoreController {
  constructor(@Inject(ScoreService) private readonly score: ScoreService) {}

  @Get(":membreId")
  consulter(@Param("membreId") membreId: string, @MembreAuthentifie() demandeurId: string) {
    return this.score.consulterPour(membreId, demandeurId);
  }
}
