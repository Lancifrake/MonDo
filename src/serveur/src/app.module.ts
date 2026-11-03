import { Module } from "@nestjs/common";
import { EvenementsModule } from "./evenements/evenements.module.js";
import { CerclesModule } from "./modules/cercles/cercles.module.js";
import { ComptesModule } from "./modules/comptes/comptes.module.js";
import { CotisationsModule } from "./modules/cotisations/cotisations.module.js";
import { PlanificateurModule } from "./modules/planificateur/planificateur.module.js";
import { PreuveModule } from "./modules/preuve/preuve.module.js";
import { ScoreModule } from "./modules/score/score.module.js";

@Module({
  imports: [EvenementsModule, ComptesModule, CerclesModule, ScoreModule, CotisationsModule, PlanificateurModule, PreuveModule],
})
export class AppModule {}
