import { Body, Controller, Get, Inject, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../../authentification/garde.js";
import { schemaModeAssistant } from "../../validation/schemas.js";
import { ValidationSchema } from "../../validation/validation.js";
import { AssistantService } from "./assistant.service.js";

@Controller("assistant")
export class AssistantController {
  constructor(@Inject(AssistantService) private readonly assistant: AssistantService) {}

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
