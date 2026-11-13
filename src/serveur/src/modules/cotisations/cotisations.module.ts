import { Module } from "@nestjs/common";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsController } from "./cotisations.controller.js";
import { CotisationsService } from "./cotisations.service.js";
import { SommesDuesController } from "./sommes-dues.controller.js";
import { SommesDuesService } from "./sommes-dues.service.js";
import { PaiementsSimulesService } from "./paiements-simules.service.js";
import { CONNECTEUR_MOBILE_MONEY, ConnecteurMobileMoneySimule } from "../../paiement/connecteur-mobile-money.js";

@Module({
  imports: [ComptesModule],
  controllers: [CotisationsController, SommesDuesController],
  providers: [
    CotisationsService,
    SommesDuesService,
    PaiementsSimulesService,
    { provide: CONNECTEUR_MOBILE_MONEY, useClass: ConnecteurMobileMoneySimule },
  ],
  exports: [CotisationsService, SommesDuesService, PaiementsSimulesService],
})
export class CotisationsModule {}
