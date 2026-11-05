import { Module } from "@nestjs/common";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { LitigesController } from "./litiges.controller.js";
import { LitigesService } from "./litiges.service.js";

/** Litiges sur un paiement déclaré non confirmé, tranchés par un administrateur (décision 04). */
@Module({ imports: [CotisationsModule], controllers: [LitigesController], providers: [LitigesService] })
export class LitigesModule {}
