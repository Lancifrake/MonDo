import { Module } from "@nestjs/common";
import { DEPOT_EVENEMENTS_SCORE, DepotEvenementsScoreMemoire } from "./depot-evenements-score.js";
import { ScoreController } from "./score.controller.js";
import { ScoreService } from "./score.service.js";

@Module({
  controllers: [ScoreController],
  providers: [ScoreService, { provide: DEPOT_EVENEMENTS_SCORE, useClass: DepotEvenementsScoreMemoire }],
  exports: [ScoreService],
})
export class ScoreModule {}
