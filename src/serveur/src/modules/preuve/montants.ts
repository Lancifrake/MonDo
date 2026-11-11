export interface MontantDu {
  cotisations: number;
  penalites: number;
  total: number;
}

/** Une cotisation réclamée : ce qui est dû au bénéficiaire de son tour, pénalité comprise. */
export interface LigneReclamee {
  cotisationId: string;
  tour: number;
  beneficiaireId: string;
  montant: number;
  /** Pénalité du règlement si la fin de grâce de cette cotisation est passée, sinon 0. */
  penalite: number;
}

/**
 * Montant réclamé par une mise en demeure : les cotisations échues non confirmées, plus la pénalité de retard
 * du règlement signé pour chacune de celles dont la fin de grâce est passée. La pénalité revient au
 * bénéficiaire du tour, une fois par cotisation (choix de David, 11/11). Jamais calculé après coup : seuls des
 * montants acceptés à l'avance rendent la créance certaine et liquide (docs/juridique/recours-legaux.md).
 */
export function calculerMontantDu(lignes: readonly Pick<LigneReclamee, "montant" | "penalite">[]): MontantDu {
  const cotisations = lignes.reduce((s, l) => s + l.montant, 0);
  const penalites = lignes.reduce((s, l) => s + l.penalite, 0);
  return { cotisations, penalites, total: cotisations + penalites };
}
