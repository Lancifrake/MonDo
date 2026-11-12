import { Module } from "@nestjs/common";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { ScoreModule } from "../score/score.module.js";
import { CerclesController } from "./cercles.controller.js";
import { CerclesService } from "./cercles.service.js";

@Module({
  imports: [ComptesModule, ScoreModule, CotisationsModule],
  controllers: [CerclesController],
  providers: [CerclesService],
  exports: [CerclesService],
})
export class CerclesModule {}
