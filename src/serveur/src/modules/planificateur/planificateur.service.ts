import { Inject, Injectable } from "@nestjs/common";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";

/** Tâches rejouables : un identifiant unique par constat évite d'envoyer deux fois la même chose (décision 02, règle 5). */
@Injectable()
export class PlanificateurService {
  private readonly dejaTraites = new Set<string>();

  constructor(@Inject(EvenementsInternes) private readonly evenements: EvenementsInternes) {}

  constaterDefaut(cercleId: string, membreId: string, tour: number): boolean {
    const idTache = `defaut:${cercleId}:${membreId}:${tour}`;
    if (this.dejaTraites.has(idTache)) return false;
    this.dejaTraites.add(idTache);
    this.evenements.publier({ type: "defaut_constate", cercleId, membreId });
    return true;
  }
}
