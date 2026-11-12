import { SCORE_MAX, SCORE_MIN, pointsDe, type EvenementScore } from "./evenements.js";

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
