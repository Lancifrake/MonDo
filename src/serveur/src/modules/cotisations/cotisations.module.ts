import { Module } from "@nestjs/common";
import { CotisationsController } from "./cotisations.controller.js";
import { CotisationsService } from "./cotisations.service.js";

@Module({ controllers: [CotisationsController], providers: [CotisationsService], exports: [CotisationsService] })
export class CotisationsModule {}
