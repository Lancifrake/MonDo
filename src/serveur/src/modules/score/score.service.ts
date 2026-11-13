import { ForbiddenException, Inject, Injectable, type OnModuleInit } from "@nestjs/common";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { calculerScore, expliquerScore, resumerHistorique, retracerScore } from "../../score/score.js";
import { DepotEvenementsScore } from "./depot-evenements-score.js";

@Injectable()
export class ScoreService implements OnModuleInit {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(DepotEvenementsScore) private readonly depot: DepotEvenementsScore,
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
    this.evenements.ecouter("adhesion_enregistree", (e) =>
      this.depot.ajouterMembre(e.cercleId, e.membreId, e.cerclePrive),
    );
    this.evenements.ecouter("depart_enregistre", (e) =>
      this.depot.ajouter(e.membreId, { type: "depart", cercleId: e.cercleId, date: e.partiLe }),
    );
    this.evenements.ecouter("cycle_termine", (e) =>
      this.depot.ajouter(e.membreId, { type: "cycle_termine", cercleId: e.cercleId, date: date() }),
    );
  }

  /** Score visible par le membre lui-même et par les membres d'un cercle commun (choix de David, 06/11). */
  async consulterPour(membreId: string, demandeurId: string) {
    if (membreId !== demandeurId && !(await this.depot.partagentUnCercle(membreId, demandeurId))) {
      throw new ForbiddenException("Score visible par le membre et par les membres de ses cercles");
    }
    const evenements = await this.depot.lister(membreId);
    const resume = { membreId, score: calculerScore(evenements), ...resumerHistorique(evenements) };
    // L'explication est visible de ceux qui voient le score ; le détail événement par événement, qui nomme
    // les cercles du membre, reste à lui seul.
    return {
      ...resume,
      explication: expliquerScore(evenements),
      ...(membreId === demandeurId ? { historique: retracerScore(evenements) } : {}),
    };
  }

  async consulter(membreId: string) {
    const historique = await this.depot.lister(membreId);
    return { membreId, score: calculerScore(historique), ...resumerHistorique(historique) };
  }
}
