/** Montant lisible dans un SMS : espace ordinaire entre les milliers, pour rester dans l'alphabet GSM. */
export const fcfa = (montant: number) => `${String(montant).replace(/\B(?=(\d{3})+(?!\d))/g, " ")} FCFA`;
