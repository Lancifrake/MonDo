/**
 * Frais du modèle A (choix de David, 11/11 ; règle détaillée dans la décision 05). Les places du début paient
 * des frais sur la cagnotte nominale : 8 % pour la place 1, dégressif jusqu'à 0 % à la première place du
 * milieu. Moitié pour MonDo, moitié en remise pour les places de fin, à parts égales.
 */
export interface LigneBareme {
  /** Place du début qui paie (1 = premier à recevoir). */
  place: number;
  /** Total dû par le bénéficiaire de cette place : part de MonDo plus les remises. */
  frais: number;
  partMonDo: number;
  /** Somme versée à chacun des membres d'une place de fin. */
  remiseParPlaceDeFin: number;
}

/** 8 %, en dix-millièmes, pour ne calculer qu'avec des entiers. */
export const TAUX_PLACE_1_DIX_MILLIEMES = 800;

/** Nombre de places du début, égal au nombre de places de fin : un tiers du cercle, arrondi par défaut. */
export const taillesDesZones = (nombreMembres: number) => {
  const debut = Math.floor(nombreMembres / 3);
  return { debut, fin: debut, premierePlaceDeFin: nombreMembres - debut + 1 };
};

/**
 * Barème en francs, place par place, à écrire dans le règlement signé. Tout est arrondi à l'entier inférieur,
 * en faveur de celui qui paie : les frais dus sont la somme des parts, jamais plus que le taux.
 */
export function calculerBareme(nombreMembres: number, montant: number): LigneBareme[] {
  const { debut: d } = taillesDesZones(nombreMembres);
  const cagnotte = (nombreMembres - 1) * montant;
  const lignes: LigneBareme[] = [];
  for (let place = 1; place <= d; place++) {
    // Frais bruts = cagnotte × 8 % × (d + 1 − place) / d, gardés en fraction jusqu'au dernier moment.
    const numerateur = cagnotte * TAUX_PLACE_1_DIX_MILLIEMES * (d + 1 - place);
    const denominateur = d * 10_000;
    const partMonDo = Math.floor(numerateur / (2 * denominateur));
    const remiseParPlaceDeFin = Math.floor(numerateur / (2 * denominateur * d));
    lignes.push({ place, frais: partMonDo + d * remiseParPlaceDeFin, partMonDo, remiseParPlaceDeFin });
  }
  return lignes;
}

/** Vrai si le barème écrit dans le règlement est exactement celui du calcul. */
export function baremeExact(
  bareme: readonly LigneBareme[] | undefined,
  nombreMembres: number,
  montant: number,
): boolean {
  const attendu = calculerBareme(nombreMembres, montant);
  return (
    bareme !== undefined &&
    bareme.length === attendu.length &&
    attendu.every((a, i) => {
      const b = bareme[i]!;
      return (
        b.place === a.place &&
        b.frais === a.frais &&
        b.partMonDo === a.partMonDo &&
        b.remiseParPlaceDeFin === a.remiseParPlaceDeFin
      );
    })
  );
}
