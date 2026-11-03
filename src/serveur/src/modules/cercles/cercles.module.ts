import { Module } from "@nestjs/common";
import { ComptesModule } from "../comptes/comptes.module.js";
import { ScoreModule } from "../score/score.module.js";
import { CerclesController } from "./cercles.controller.js";
import { CerclesService } from "./cercles.service.js";

@Module({
  imports: [ComptesModule, ScoreModule],
  controllers: [CerclesController],
  providers: [CerclesService],
  exports: [CerclesService],
})
export class CerclesModule {}
