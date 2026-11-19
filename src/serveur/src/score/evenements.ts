export type TypeEvenementScore =
  "cotisation_a_temps" | "cotisation_en_retard" | "defaut" | "cycle_termine" | "depart" | "parrainage_reussi";

export interface EvenementScore {
  type: TypeEvenementScore;
  cercleId: string;
  date: string;
  /** Événement survenu dans un cercle privé : les gains comptent moitié moins, les pertes restent entières. */
  cerclePrive?: boolean;
}

// Valeurs de départ de docs/conception/score-et-places.md, à régler par simulation.
export const POINTS: Record<TypeEvenementScore, number> = {
  cotisation_a_temps: 4,
  cotisation_en_retard: -1,
  defaut: -30,
  cycle_termine: 10,
  depart: -15,
  /** Le filleul a terminé un cycle sans défaut (cahier des charges, section 7). */
  parrainage_reussi: 2,
};

export const SCORE_MIN = 0;
export const SCORE_MAX = 100;

/** Points d'un événement. Le score sert à juger des inconnus : entre amis, on gagne moitié moins (11/11). */
export const pointsDe = (e: EvenementScore): number => {
  const points = POINTS[e.type];
  return e.cerclePrive && points > 0 ? Math.trunc(points / 2) : points;
};

/**
 * Le score appliqué à un pas. Les pertes sont entières ; les gains sont multipliés par le carré de la
 * distance qui reste à 100 : plus on est haut, plus chaque point coûte cher, et 100 reste hors d'atteinte
 * (un cercle hebdomadaire de 10 membres sans retard : 34, 51, 61, 67, 72 après 1 à 5 cycles).
 * Le calcul garde les décimales ; on arrondit seulement à l'affichage.
 */
export const appliquerPoints = (score: number, points: number): number => {
  const gain = points > 0 ? points * ((SCORE_MAX - score) / SCORE_MAX) ** 2 : points;
  return Math.min(SCORE_MAX, Math.max(SCORE_MIN, score + gain));
};
