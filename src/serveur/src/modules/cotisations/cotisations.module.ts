import { Module } from "@nestjs/common";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsController } from "./cotisations.controller.js";
import { CotisationsService } from "./cotisations.service.js";

@Module({
  imports: [ComptesModule],
  controllers: [CotisationsController],
  providers: [CotisationsService],
  exports: [CotisationsService],
})
export class CotisationsModule {}
