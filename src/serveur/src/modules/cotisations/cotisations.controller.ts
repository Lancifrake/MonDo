import { Body, Controller, Inject, Param, Post } from "@nestjs/common";
import { CotisationsService, type Cotisation } from "./cotisations.service.js";

@Controller("cotisations")
export class CotisationsController {
  constructor(@Inject(CotisationsService) private readonly cotisations: CotisationsService) {}

  @Post()
  creer(@Body() corps: Omit<Cotisation, "id" | "statut">) {
    return this.cotisations.creer(corps);
  }

  @Post(":id/paiement")
  declarer(@Param("id") id: string, @Body() corps: { referenceTransaction: string }) {
    return this.cotisations.declarerPaiement(id, corps.referenceTransaction);
  }

  @Post(":id/confirmation")
  confirmer(@Param("id") id: string, @Body() corps: { membreId: string }) {
    return this.cotisations.confirmer(id, corps.membreId);
  }
}
