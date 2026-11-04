export interface TourPlanifie {
  numero: number;
  beneficiaireId: string;
  /** Date limite des cotisations du tour, jour où le bénéficiaire reçoit la cagnotte. */
  dateLimite: string;
}

const JOUR_MS = 24 * 60 * 60 * 1000;

/** k-ième échéance après la première, toujours calculée depuis la première : pas de dérive (31 janvier, 28 février, 31 mars). */
function echeance(premiere: Date, frequence: "hebdomadaire" | "mensuelle", k: number): Date {
  if (frequence === "hebdomadaire") return new Date(premiere.getTime() + 7 * k * JOUR_MS);
  const mois = premiere.getUTCMonth() + k;
  const annee = premiere.getUTCFullYear() + Math.floor(mois / 12);
  const moisDansAnnee = ((mois % 12) + 12) % 12;
  const dernierJour = new Date(Date.UTC(annee, moisDansAnnee + 1, 0)).getUTCDate();
  const d = new Date(premiere);
  d.setUTCFullYear(annee, moisDansAnnee, Math.min(premiere.getUTCDate(), dernierJour));
  return d;
}

/**
 * Calendrier figé quand le cercle est complet (choix de David, 05/11) : la date du premier tour est
 * dans le règlement signé ; si le cercle se complète à cette date ou après, le départ est décalé
 * d'autant de périodes qu'il faut. Un tour par membre, dans l'ordre de passage.
 */
export function calendrierDesTours(d: {
  ordre: string[];
  frequence: "hebdomadaire" | "mensuelle";
  datePremierTour: string;
  completLe: string;
}): TourPlanifie[] {
  const premiere = new Date(d.datePremierTour);
  const complet = Date.parse(d.completLe);
  let decalage = 0;
  while (echeance(premiere, d.frequence, decalage).getTime() <= complet) decalage++;
  return d.ordre.map((beneficiaireId, i) => ({
    numero: i + 1,
    beneficiaireId,
    dateLimite: echeance(premiere, d.frequence, decalage + i).toISOString(),
  }));
}
