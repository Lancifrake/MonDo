import { POINTS, SCORE_MAX, SCORE_MIN, pointsDe, type EvenementScore } from "./evenements.js";

/**
 * Le score n'est jamais écrit à la main : c'est le rejeu, dans l'ordre, des événements.
 * Le plafond et le plancher s'appliquent à chaque pas (un nouveau à 0 qui perd 1 point reste à 0).
 */
export function calculerScore(evenements: readonly EvenementScore[]): number {
  let score = SCORE_MIN;
  for (const e of evenements) {
    score = Math.min(SCORE_MAX, Math.max(SCORE_MIN, score + pointsDe(e)));
  }
  return score;
}

/** À afficher à côté du score : un nouveau et un défaillant tombé à 0 ne sont pas la même chose. */
export function resumerHistorique(evenements: readonly EvenementScore[]) {
  return {
    cyclesTermines: evenements.filter((e) => e.type === "cycle_termine").length,
    defauts: evenements.filter((e) => e.type === "defaut").length,
  };
}

export interface EtapeDuScore {
  date: string;
  type: EvenementScore["type"];
  cercleId: string;
  cerclePrive: boolean;
  /** Points de l'événement, après la règle des cercles privés. */
  points: number;
  /** Score après l'événement, plancher et plafond appliqués. */
  scoreApres: number;
}

/** Évolution du score, événement par événement (cahier des charges, M6). */
export function retracerScore(evenements: readonly EvenementScore[]): EtapeDuScore[] {
  let score = SCORE_MIN;
  return evenements.map((e) => {
    const points = pointsDe(e);
    score = Math.min(SCORE_MAX, Math.max(SCORE_MIN, score + points));
    return {
      date: e.date,
      type: e.type,
      cercleId: e.cercleId,
      cerclePrive: e.cerclePrive === true,
      points,
      scoreApres: score,
    };
  });
}

const pluriel = (n: number, singulier: string, plurielTexte: string) => `${n} ${n > 1 ? plurielTexte : singulier}`;

/** Le score en quelques phrases simples, pour le membre et pour ceux qui le voient. */
export function expliquerScore(evenements: readonly EvenementScore[]): string[] {
  if (evenements.length === 0) {
    return ["Nouveau membre : le score commence à 0. Il monte avec chaque cotisation payée à temps."];
  }
  const compter = (type: EvenementScore["type"]) => evenements.filter((e) => e.type === type).length;
  const phrases = [`Score de ${calculerScore(evenements)} sur 100.`];
  const aTemps = compter("cotisation_a_temps");
  const enRetard = compter("cotisation_en_retard");
  const cycles = compter("cycle_termine");
  const defauts = compter("defaut");
  const departs = compter("depart");
  const gains = [
    aTemps && `${pluriel(aTemps, "cotisation payée à temps", "cotisations payées à temps")} (+4 chacune)`,
    cycles && `${pluriel(cycles, "cycle terminé sans défaut", "cycles terminés sans défaut")} (+10 chacun)`,
  ].filter(Boolean);
  if (gains.length > 0) phrases.push(`Ce qui le fait monter : ${gains.join(", ")}.`);
  const pertes = [
    enRetard && `${pluriel(enRetard, "cotisation payée en retard", "cotisations payées en retard")} (−1 chacune)`,
    defauts && `${pluriel(defauts, "défaut", "défauts")} de paiement (−30 chacun)`,
    departs && `${pluriel(departs, "départ", "départs")} en cours de cycle (−15 chacun)`,
  ].filter(Boolean);
  phrases.push(pertes.length > 0 ? `Ce qui le fait baisser : ${pertes.join(", ")}.` : "Aucun retard, aucun défaut.");
  if (evenements.some((e) => e.cerclePrive && POINTS[e.type] > 0)) {
    phrases.push("Dans les cercles privés, les gains comptent moitié moins ; les pertes comptent en entier.");
  }
  if (defauts > 0) phrases.push("Après un défaut, les premières places sont fermées pendant un temps.");
  return phrases;
}
