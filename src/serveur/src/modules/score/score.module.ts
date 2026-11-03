import { Module } from "@nestjs/common";
import { DepotEvenementsScore } from "./depot-evenements-score.js";
import { ScoreController } from "./score.controller.js";
import { ScoreService } from "./score.service.js";

@Module({ controllers: [ScoreController], providers: [ScoreService, DepotEvenementsScore], exports: [ScoreService] })
export class ScoreModule {}
