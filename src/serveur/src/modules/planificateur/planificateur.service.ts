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

  constaterDefaut(cercleId: string, membreId: string, tour: number, maintenant: Date = new Date()): Promise<boolean> {
    return this.traiterUneFois(`defaut:${cercleId}:${membreId}:${tour}`, {
      type: "defaut_constate",
      cercleId,
      membreId,
      tour,
      constateLe: maintenant.toISOString(),
    });
  }

  /**
   * Examine les cotisations dues : échéance proche ou dépassée, une fois par jour et par cotisation ;
   * après la fin de grâce, défaut constaté, une seule fois par tour. Une cotisation déclarée mais pas
   * confirmée n'est jamais un défaut du payeur : à la fin de grâce, un litige s'ouvre tout seul (choix de
   * David, 05/11). Puis les fins de cycle. L'échec d'une tâche
   * n'arrête pas l'examen des autres.
   */
  async examinerEcheances(maintenant: Date = new Date()): Promise<{ traitees: number; echecs: number }> {
    let traitees = 0;
    let echecs = 0;
    for (const c of await this.cotisations.listerDues()) {
      if (c.tour > 0 && maintenant.getTime() > Date.parse(c.finGrace)) {
        try {
          if (await this.constaterDefaut(c.cercleId, c.payeurId, c.tour, maintenant)) traitees++;
        } catch {
          echecs++;
        }
        continue;
      }
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
    for (const c of await this.cotisations.listerDeclarees()) {
      if (maintenant.getTime() <= Date.parse(c.finGrace)) continue;
      try {
        // Une nouvelle déclaration (après un refus) peut rouvrir un litige : l'identifiant suit la déclaration.
        const idTache = `litige:${c.id}:${c.declareeLe ?? ""}`;
        const evenement: EvenementInterne = {
          type: "confirmation_manquante",
          cercleId: c.cercleId,
          membreId: c.payeurId,
          cotisationId: c.id,
        };
        if (await this.traiterUneFois(idTache, evenement)) traitees++;
      } catch {
        echecs++;
      }
    }
    const cycles = await this.examinerFinsDeCycle(maintenant);
    return { traitees: traitees + cycles.traitees, echecs: echecs + cycles.echecs };
  }

  /**
   * Cycle terminé (choix de David, 05/11) : fin de grâce du dernier tour passée, aucun défaut constaté pour
   * le membre dans ce cercle, toutes ses cotisations confirmées par le bénéficiaire. Si une confirmation
   * manque, le bonus attend le passage qui suit la confirmation. Une seule fois par membre et par cercle.
   */
  private async examinerFinsDeCycle(maintenant: Date): Promise<{ traitees: number; echecs: number }> {
    let traitees = 0;
    let echecs = 0;
    const bilans = await this.cotisations.bilansDeCycle();
    for (const b of bilans) {
      if (!b.toutConfirme || maintenant.getTime() <= Date.parse(b.finCycle)) continue;
      try {
        if (await this.aFaitDefaut(b.cercleId, b.membreId)) continue;
        const evenement: EvenementInterne = { type: "cycle_termine", cercleId: b.cercleId, membreId: b.membreId };
        if (await this.traiterUneFois(`cycle:${b.cercleId}:${b.membreId}`, evenement)) traitees++;
      } catch {
        echecs++;
      }
    }
    // Cercle terminé à la fin de grâce du dernier tour, impayés ou non (choix de David, 05/11).
    const finsDeCercle = new Map(bilans.map((b) => [b.cercleId, b.finCycle]));
    for (const [cercleId, termineLe] of finsDeCercle) {
      if (maintenant.getTime() <= Date.parse(termineLe)) continue;
      try {
        if (await this.traiterUneFois(`cercle_termine:${cercleId}`, { type: "cercle_termine", cercleId, termineLe })) {
          traitees++;
        }
      } catch {
        echecs++;
      }
    }
    return { traitees, echecs };
  }

  /** Les défauts constatés sont les tâches `defaut:cercle:membre:tour` déjà traitées par ce module. */
  private async aFaitDefaut(cercleId: string, membreId: string): Promise<boolean> {
    const lignes = await this.base.requete(
      "SELECT 1 FROM planificateur.taches_traitees WHERE starts_with(id, $1) LIMIT 1",
      [`defaut:${cercleId}:${membreId}:`],
    );
    return lignes.length > 0;
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
