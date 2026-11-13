import { Module } from "@nestjs/common";
import { ScoreModule } from "../score/score.module.js";
import { AdministrationIdentiteController } from "./administration-identite.controller.js";
import { AdministrationRecuperationController } from "./administration-recuperation.controller.js";
import { BlocagesService } from "./blocages.service.js";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { IdentiteService } from "./identite.service.js";
import { OtpService } from "./otp.service.js";
import { ParrainagesService } from "./parrainages.service.js";
import { RecuperationService } from "./recuperation.service.js";

@Module({
  imports: [ScoreModule],
  controllers: [ComptesController, AdministrationIdentiteController, AdministrationRecuperationController],
  providers: [
    ComptesService,
    OtpService,
    ContactConfianceService,
    IdentiteService,
    BlocagesService,
    RecuperationService,
    ParrainagesService,
  ],
  exports: [
    OtpService,
    ComptesService,
    ContactConfianceService,
    IdentiteService,
    BlocagesService,
    RecuperationService,
    ParrainagesService,
  ],
})
export class ComptesModule {}
