import { Inject, Injectable } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import type { EvenementScore, TypeEvenementScore } from "../../score/evenements.js";

/** Tables du module Score (schéma « score »). Les événements ne sont jamais modifiés ni supprimés. */
@Injectable()
export class DepotEvenementsScore {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  async ajouter(membreId: string, e: EvenementScore): Promise<void> {
    await this.base.requete("INSERT INTO score.evenements (membre_id, type, cercle_id, date) VALUES ($1, $2, $3, $4)", [
      membreId,
      e.type,
      e.cercleId,
      e.date,
    ]);
  }

  async lister(membreId: string): Promise<EvenementScore[]> {
    const lignes = await this.base.requete<{ type: TypeEvenementScore; cercle_id: string; date: Date | string }>(
      "SELECT type, cercle_id, date FROM score.evenements WHERE membre_id = $1 ORDER BY id",
      [membreId],
    );
    return lignes.map((l) => ({ type: l.type, cercleId: l.cercle_id, date: new Date(l.date).toISOString() }));
  }
}
