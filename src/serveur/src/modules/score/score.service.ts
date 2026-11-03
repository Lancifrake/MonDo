import { Inject, Injectable, type OnModuleInit } from "@nestjs/common";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { calculerScore, resumerHistorique } from "../../score/score.js";
import { DEPOT_EVENEMENTS_SCORE, type DepotEvenementsScore } from "./depot-evenements-score.js";

@Injectable()
export class ScoreService implements OnModuleInit {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(DEPOT_EVENEMENTS_SCORE) private readonly depot: DepotEvenementsScore,
  ) {}

  /** Le score ne se modifie que par les événements : jamais d'écriture directe. */
  onModuleInit(): void {
    const date = () => new Date().toISOString();
    this.evenements.ecouter("cotisation_confirmee", (e) =>
      this.depot.ajouter(e.membreId, {
        type: e.aTemps ? "cotisation_a_temps" : "cotisation_en_retard",
        cercleId: e.cercleId,
        date: date(),
      }),
    );
    this.evenements.ecouter("defaut_constate", (e) =>
      this.depot.ajouter(e.membreId, { type: "defaut", cercleId: e.cercleId, date: date() }),
    );
    this.evenements.ecouter("cycle_termine", (e) =>
      this.depot.ajouter(e.membreId, { type: "cycle_termine", cercleId: e.cercleId, date: date() }),
    );
  }

  consulter(membreId: string) {
    const historique = this.depot.lister(membreId);
    return { membreId, score: calculerScore(historique), ...resumerHistorique(historique) };
  }
}
