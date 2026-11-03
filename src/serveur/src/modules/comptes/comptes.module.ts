import { Module } from "@nestjs/common";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";
import { OtpService } from "./otp.service.js";

@Module({ controllers: [ComptesController], providers: [ComptesService, OtpService], exports: [ComptesService] })
export class ComptesModule {}
