import { Module } from "@nestjs/common";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsController } from "./cotisations.controller.js";
import { CotisationsService } from "./cotisations.service.js";
import { SommesDuesController } from "./sommes-dues.controller.js";
import { SommesDuesService } from "./sommes-dues.service.js";

@Module({
  imports: [ComptesModule],
  controllers: [CotisationsController, SommesDuesController],
  providers: [CotisationsService, SommesDuesService],
  exports: [CotisationsService, SommesDuesService],
})
export class CotisationsModule {}
