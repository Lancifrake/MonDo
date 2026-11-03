import { Module } from "@nestjs/common";
import { ComptesController } from "./comptes.controller.js";
import { ComptesService } from "./comptes.service.js";

@Module({ controllers: [ComptesController], providers: [ComptesService], exports: [ComptesService] })
export class ComptesModule {}
