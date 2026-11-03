export type TypeEvenementScore =
  | "cotisation_a_temps"
  | "cotisation_en_retard"
  | "defaut"
  | "cycle_termine"
  | "depart";

export interface EvenementScore {
  type: TypeEvenementScore;
  cercleId: string;
  date: string;
}

// Valeurs de départ de docs/conception/score-et-places.md, à régler par simulation.
export const POINTS: Record<TypeEvenementScore, number> = {
  cotisation_a_temps: 4,
  cotisation_en_retard: -1,
  defaut: -30,
  cycle_termine: 10,
  depart: -15,
};

export const SCORE_MIN = 0;
export const SCORE_MAX = 100;
