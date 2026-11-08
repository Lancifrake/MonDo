import { PARAMETRES_PAR_DEFAUT, type ParametresOrdre, type Zone } from "./ordre-de-passage.js";

/**
 * Choix de la place, « le score ouvre, le membre choisit » (choix de David, 08/11, décision 05).
 * Chaque membre signe la place qu'il souhaite ; l'attribution définitive se fait quand le cercle est complet.
 */
export interface Candidat {
  id: string;
  score: number;
  /** Rang d'inscription au cercle, 1 = premier inscrit. */
  rangInscription: number;
  /** Place souhaitée, signée dans l'engagement (1 = premier à recevoir). */
  placeSouhaitee: number;
  /** Défaut au cycle précédent : plus de place au début. */
  exclusDuDebut?: boolean;
}

export interface PlaceObtenue {
  position: number;
  zone: Zone;
  membre: Candidat;
}

/** Zones d'un cercle de n membres : début et fin font un tiers chacun (arrondi par défaut), le milieu le reste. */
function zones(n: number) {
  const debut = Math.floor(n / 3);
  const milieu = n - 2 * debut;
  return { finDuDebut: debut, finDuMilieu: debut + milieu };
}

const zoneDe = (position: number, n: number): Zone => {
  const { finDuDebut, finDuMilieu } = zones(n);
  return position <= finDuDebut ? "debut" : position <= finDuMilieu ? "milieu" : "fin";
};

/** Place la plus tôt que permet le score dans un cercle de n membres. On peut toujours choisir plus tard. */
export function premierePlaceAutorisee(
  score: number,
  n: number,
  options: { exclusDuDebut?: boolean; parametres?: ParametresOrdre } = {},
): number {
  const { seuilDebut, seuilMilieu } = options.parametres ?? PARAMETRES_PAR_DEFAUT;
  const { finDuDebut, finDuMilieu } = zones(n);
  if (!options.exclusDuDebut && score >= seuilDebut) return 1;
  if (score >= seuilMilieu) return finDuDebut + 1;
  return finDuMilieu + 1;
}

/**
 * Attribution déterministe, sans tirage ni enchères :
 * 1. par priorité (score décroissant, puis premier inscrit), chacun prend la place souhaitée si elle est
 *    libre ; sinon la place libre la plus proche parmi celles que permet son score, la plus tardive à égalité
 *    (reculer ne met personne en danger). Jamais plus tôt que son score, même si la place souhaitée l'était
 *    (score baissé depuis l'adhésion) ;
 * 2. ceux qui n'ont trouvé aucune place permise (cercle de nouveaux, par exemple) prennent les places restantes,
 *    toutes plus tôt que leur score : le mieux classé reçoit la plus tôt.
 */
export function attribuerLesPlaces(
  candidats: readonly Candidat[],
  parametres: ParametresOrdre = PARAMETRES_PAR_DEFAUT,
): PlaceObtenue[] {
  const n = candidats.length;
  const parPriorite = [...candidats].sort(
    (a, b) => b.score - a.score || a.rangInscription - b.rangInscription || a.id.localeCompare(b.id),
  );
  const occupant = new Map<number, Candidat>();
  const sansPlace: Candidat[] = [];

  for (const m of parPriorite) {
    const plusTot = premierePlaceAutorisee(m.score, n, {
      ...(m.exclusDuDebut ? { exclusDuDebut: true } : {}),
      parametres,
    });
    const cible = Math.min(n, Math.max(m.placeSouhaitee, plusTot));
    let choisie: number | undefined;
    for (let p = plusTot; p <= n; p++) {
      if (occupant.has(p)) continue;
      // Plus proche de la cible ; à égalité, la plus tardive (le parcours croissant garde la dernière).
      if (choisie === undefined || Math.abs(p - cible) <= Math.abs(choisie - cible)) choisie = p;
    }
    if (choisie === undefined) sansPlace.push(m);
    else occupant.set(choisie, m);
  }

  const restantes = Array.from({ length: n }, (_, i) => i + 1).filter((p) => !occupant.has(p));
  sansPlace.forEach((m, i) => occupant.set(restantes[i]!, m));

  return Array.from({ length: n }, (_, i) => ({
    position: i + 1,
    zone: zoneDe(i + 1, n),
    membre: occupant.get(i + 1)!,
  }));
}
