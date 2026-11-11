import { Module } from "@nestjs/common";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { OtpService } from "./otp.service.js";

@Module({
  controllers: [ComptesController],
  providers: [ComptesService, OtpService, ContactConfianceService],
  exports: [ComptesService, ContactConfianceService],
})
export class ComptesModule {}
