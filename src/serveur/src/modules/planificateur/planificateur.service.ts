import { Inject, Injectable } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes, type EvenementInterne } from "../../evenements/evenements-internes.js";
import { CotisationsService } from "../cotisations/cotisations.service.js";

const JOUR_MS = 24 * 60 * 60 * 1000;

/** Tâches rejouables : un identifiant unique par tâche évite de traiter deux fois la même chose (décision 02, règle 5). */
@Injectable()
export class PlanificateurService {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
  ) {}

  constaterDefaut(cercleId: string, membreId: string, tour: number): Promise<boolean> {
    return this.traiterUneFois(`defaut:${cercleId}:${membreId}:${tour}`, {
      type: "defaut_constate",
      cercleId,
      membreId,
      tour,
    });
  }

  /**
   * Examine les cotisations dues : échéance proche ou dépassée, une fois par jour et par cotisation.
   * L'échec d'une cotisation n'arrête pas l'examen des autres.
   */
  async examinerEcheances(maintenant: Date = new Date()): Promise<{ traitees: number; echecs: number }> {
    let traitees = 0;
    let echecs = 0;
    for (const c of await this.cotisations.listerDues()) {
      const ecart = new Date(c.dateLimite).getTime() - maintenant.getTime();
      const commun = { cercleId: c.cercleId, membreId: c.payeurId, cotisationId: c.id };
      const [idTache, evenement]: [string, EvenementInterne] =
        ecart >= 0
          ? [
              `echeance:${c.id}:J-${Math.ceil(ecart / JOUR_MS)}`,
              { type: "echeance_proche", ...commun, joursRestants: Math.ceil(ecart / JOUR_MS) },
            ]
          : [
              `retard:${c.id}:J+${Math.ceil(-ecart / JOUR_MS)}`,
              { type: "echeance_depassee", ...commun, joursDeRetard: Math.ceil(-ecart / JOUR_MS) },
            ];
      try {
        if (await this.traiterUneFois(idTache, evenement)) traitees++;
      } catch {
        echecs++;
      }
    }
    return { traitees, echecs };
  }

  private async traiterUneFois(idTache: string, evenement: EvenementInterne): Promise<boolean> {
    const prise = await this.base.requete(
      "INSERT INTO planificateur.taches_traitees (id) VALUES ($1) ON CONFLICT DO NOTHING RETURNING id",
      [idTache],
    );
    if (prise.length === 0) return false;
    try {
      await this.evenements.publier(evenement);
    } catch (e) {
      // Échec de traitement : la tâche redevient rejouable.
      await this.base.requete("DELETE FROM planificateur.taches_traitees WHERE id = $1", [idTache]);
      throw e;
    }
    return true;
  }
}
