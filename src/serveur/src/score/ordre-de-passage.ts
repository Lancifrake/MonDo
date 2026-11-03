export interface MembreCercle {
  id: string;
  score: number;
  /** Rang d'inscription au cercle, 1 = premier inscrit. Sert à départager les égalités. */
  rangInscription: number;
  /** Défaut au cycle précédent : plus de première place. */
  exclusDuDebut?: boolean;
}

export interface ParametresOrdre {
  seuilDebut: number;
  seuilMilieu: number;
}

// Valeurs de départ (docs/conception/score-et-places.md) : 60 petite cagnotte, 80 grosse, 30 milieu.
export const PARAMETRES_PAR_DEFAUT: ParametresOrdre = { seuilDebut: 60, seuilMilieu: 30 };

export type Zone = "debut" | "milieu" | "fin";

export interface PlaceAttribuee {
  position: number;
  zone: Zone;
  membre: MembreCercle;
}

/**
 * Ordre : zones (début, milieu, fin), puis score décroissant, puis ordre d'inscription.
 * Déterministe : pas de tirage au sort. Début et fin : un tiers chacun (arrondi par défaut).
 * Les places de début non remplies sont comblées par la suite de l'ordre.
 */
export function calculerOrdreDePassage(
  membres: readonly MembreCercle[],
  parametres: ParametresOrdre = PARAMETRES_PAR_DEFAUT,
): PlaceAttribuee[] {
  const n = membres.length;
  const capaciteDebut = Math.floor(n / 3);
  const capaciteMilieu = n - 2 * capaciteDebut;

  const parMerite = [...membres].sort(
    (a, b) => b.score - a.score || a.rangInscription - b.rangInscription,
  );

  const zones: Record<Zone, MembreCercle[]> = { debut: [], milieu: [], fin: [] };
  for (const m of parMerite) {
    if (!m.exclusDuDebut && m.score >= parametres.seuilDebut && zones.debut.length < capaciteDebut) {
      zones.debut.push(m);
    } else if (m.score >= parametres.seuilMilieu && zones.milieu.length < capaciteMilieu) {
      zones.milieu.push(m);
    } else {
      zones.fin.push(m);
    }
  }

  const ordre: PlaceAttribuee[] = [];
  for (const zone of ["debut", "milieu", "fin"] as const) {
    for (const membre of zones[zone]) {
      ordre.push({ position: ordre.length + 1, zone, membre });
    }
  }
  return ordre;
}
