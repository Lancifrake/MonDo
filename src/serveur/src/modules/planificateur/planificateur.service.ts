import { Inject, Injectable } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";

/** Tâches rejouables : un identifiant unique par constat évite de traiter deux fois la même chose (décision 02, règle 5). */
@Injectable()
export class PlanificateurService {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {}

  async constaterDefaut(cercleId: string, membreId: string, tour: number): Promise<boolean> {
    const idTache = `defaut:${cercleId}:${membreId}:${tour}`;
    const prise = await this.base.requete(
      "INSERT INTO planificateur.taches_traitees (id) VALUES ($1) ON CONFLICT DO NOTHING RETURNING id",
      [idTache],
    );
    if (prise.length === 0) return false;
    try {
      await this.evenements.publier({ type: "defaut_constate", cercleId, membreId });
    } catch (e) {
      // Échec de traitement : la tâche redevient rejouable.
      await this.base.requete("DELETE FROM planificateur.taches_traitees WHERE id = $1", [idTache]);
      throw e;
    }
    return true;
  }
}
