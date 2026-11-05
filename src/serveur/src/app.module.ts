import { Module } from "@nestjs/common";
import { APP_GUARD } from "@nestjs/core";
import { GardeAuthentification } from "./authentification/garde.js";
import { BaseModule } from "./base/base.module.js";
import { EvenementsModule } from "./evenements/evenements.module.js";
import { AssistantModule } from "./modules/assistant/assistant.module.js";
import { CerclesModule } from "./modules/cercles/cercles.module.js";
import { ComptesModule } from "./modules/comptes/comptes.module.js";
import { CotisationsModule } from "./modules/cotisations/cotisations.module.js";
import { PlanificateurModule } from "./modules/planificateur/planificateur.module.js";
import { PreuveModule } from "./modules/preuve/preuve.module.js";
import { ScoreModule } from "./modules/score/score.module.js";
import { RegistreModule } from "./registre/registre.module.js";
import { SanteController } from "./sante/sante.controller.js";
import { SmsModule } from "./sms/sms.module.js";

@Module({
  imports: [
    BaseModule,
    SmsModule,
    EvenementsModule,
    RegistreModule,
    ComptesModule,
    CerclesModule,
    ScoreModule,
    CotisationsModule,
    PlanificateurModule,
    PreuveModule,
    AssistantModule,
  ],
  controllers: [SanteController],
  // Toute route exige une requête signée, sauf celles marquées @Public().
  providers: [{ provide: APP_GUARD, useClass: GardeAuthentification }],
})
export class AppModule {}
