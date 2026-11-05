import { Controller, Get, Inject, ServiceUnavailableException } from "@nestjs/common";
import { Public } from "../authentification/garde.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../base/base-de-donnees.js";

/** Pour l'hébergeur et l'essai de démarrage : le serveur répond et la base est joignable. Aucune donnée. */
@Controller("sante")
export class SanteController {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  @Public()
  @Get()
  async verifier(): Promise<{ statut: "ok" }> {
    try {
      await this.base.requete("SELECT 1");
    } catch {
      throw new ServiceUnavailableException("Base de données injoignable");
    }
    return { statut: "ok" };
  }
}
