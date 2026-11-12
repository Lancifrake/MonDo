import { Module } from "@nestjs/common";
import { AdministrationIdentiteController } from "./administration-identite.controller.js";
import { AdministrationRecuperationController } from "./administration-recuperation.controller.js";
import { BlocagesService } from "./blocages.service.js";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { IdentiteService } from "./identite.service.js";
import { OtpService } from "./otp.service.js";
import { RecuperationService } from "./recuperation.service.js";

@Module({
  controllers: [ComptesController, AdministrationIdentiteController, AdministrationRecuperationController],
  providers: [
    ComptesService,
    OtpService,
    ContactConfianceService,
    IdentiteService,
    BlocagesService,
    RecuperationService,
  ],
  exports: [ComptesService, ContactConfianceService, IdentiteService, BlocagesService, RecuperationService],
})
export class ComptesModule {}
