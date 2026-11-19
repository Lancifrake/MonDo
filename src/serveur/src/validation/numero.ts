/**
 * Un téléphone = une seule écriture de son numéro. Sans cela, +237699000000, 237699000000, 00237699000000 et
 * 699000000 ouvraient quatre comptes pour le même téléphone : un membre en défaut repartait avec un score neuf
 * (audit de sécurité du 19/11/2026, lacune 1).
 *
 * Forme unique : « + », l'indicatif du pays, puis le numéro. Neuf chiffres seuls = un numéro camerounais.
 * La même règle est écrite en SQL dans la migration 035_numeros_normalises : les deux doivent rester identiques.
 */
export const FORME_NUMERO = /^\+[1-9]\d{7,14}$/;

/** Écritures acceptées en entrée, comme avant la normalisation. */
export const ENTREE_NUMERO = /^\+?\d{8,15}$/;

export function normaliserNumero(brut: string): string {
  if (brut.startsWith("+")) return brut;
  if (brut.startsWith("00")) return `+${brut.slice(2)}`;
  if (/^\d{9}$/.test(brut)) return `+237${brut}`;
  return `+${brut}`;
}

/** Le numéro normalisé, ou undefined s'il n'a pas une forme possible. */
export function numeroValide(brut: string): string | undefined {
  if (!ENTREE_NUMERO.test(brut)) return undefined;
  const n = normaliserNumero(brut);
  return FORME_NUMERO.test(n) ? n : undefined;
}
