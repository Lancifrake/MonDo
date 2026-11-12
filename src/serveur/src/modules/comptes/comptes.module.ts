import { Module } from "@nestjs/common";
import { AdministrationIdentiteController } from "./administration-identite.controller.js";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { IdentiteService } from "./identite.service.js";
import { OtpService } from "./otp.service.js";

@Module({
  controllers: [ComptesController, AdministrationIdentiteController],
  providers: [ComptesService, OtpService, ContactConfianceService, IdentiteService],
  exports: [ComptesService, ContactConfianceService, IdentiteService],
})
export class ComptesModule {}
