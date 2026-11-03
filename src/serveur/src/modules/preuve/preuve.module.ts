import { Module } from "@nestjs/common";
import { CerclesModule } from "../cercles/cercles.module.js";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { PreuveController } from "./preuve.controller.js";
import { PreuveService } from "./preuve.service.js";

/** Dossier de preuve et mises en demeure (décision 02, module 6). */
@Module({
  imports: [CerclesModule, CotisationsModule, ComptesModule],
  controllers: [PreuveController],
  providers: [PreuveService],
  exports: [PreuveService],
})
export class PreuveModule {}
