import { BadRequestException, Body, Controller, Get, Inject, Param, Post, Query } from "@nestjs/common";
import { mesurerAssistant } from "../../assistant/mesures.js";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaModeAssistant } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { AssistantService } from "./assistant.service.js";

@Controller("assistant")
export class AssistantController {
  constructor(@Inject(AssistantService) private readonly assistant: AssistantService) {}

  /**
   * Mesures du système multi-agents sur le scénario de démonstration (grille d'évaluation, décision 04) :
   * cycles, messages, durée, même résultat à chaque lancement, mémoire. Calcul pur, sans donnée de membre.
   */
  @Get("mesures")
  mesures(@Query("lancements") lancements?: string) {
    const n = lancements === undefined ? 100 : Number(lancements);
    if (!Number.isInteger(n) || n < 1 || n > 1000) throw new BadRequestException("lancements : entier de 1 à 1000");
    return mesurerAssistant(n);
  }

  @Post("cercles/:cercleId/mode")
  changerMode(
    @Param("cercleId") cercleId: string,
    @MembreAuthentifie() membreId: string,
    @Body(new ValidationSchema(schemaModeAssistant)) corps: (typeof schemaModeAssistant)["_output"],
  ) {
    return this.assistant.changerMode(cercleId, membreId, corps.mode);
  }

  @Get("cercles/:cercleId/journal")
  journal(@Param("cercleId") cercleId: string, @MembreAuthentifie() membreId: string) {
    return this.assistant.journal(cercleId, membreId);
  }

  @Post("propositions/:id/acceptation")
  accepter(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.assistant.trancher(id, membreId, "acceptee");
  }

  @Post("propositions/:id/refus")
  refuser(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.assistant.trancher(id, membreId, "refusee");
  }
}
