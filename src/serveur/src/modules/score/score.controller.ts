import { Controller, Get, Inject, Param } from "@nestjs/common";
import { ScoreService } from "./score.service.js";

@Controller("score")
export class ScoreController {
  constructor(@Inject(ScoreService) private readonly score: ScoreService) {}

  @Get(":membreId")
  consulter(@Param("membreId") membreId: string) {
    return this.score.consulter(membreId);
  }
}
