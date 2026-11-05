import { Module } from "@nestjs/common";
import { CerclesModule } from "../cercles/cercles.module.js";
import { ComptesModule } from "../comptes/comptes.module.js";
import { CotisationsModule } from "../cotisations/cotisations.module.js";
import { PreuveModule } from "../preuve/preuve.module.js";
import { AssistantController } from "./assistant.controller.js";
import { AssistantService } from "./assistant.service.js";

/** Importe Preuve : la mise en demeure est préparée avant que l'assistant décide de l'envoyer. */
@Module({
  imports: [CerclesModule, PreuveModule, CotisationsModule, ComptesModule],
  controllers: [AssistantController],
  providers: [AssistantService],
})
export class AssistantModule {}
