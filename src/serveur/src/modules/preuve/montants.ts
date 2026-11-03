export interface MontantDu {
  cotisations: number;
  penalites: number;
  total: number;
}

/**
 * Montant réclamé par une mise en demeure : les cotisations non confirmées, plus la pénalité de retard
 * fixée par le règlement signé pour chacune (flow 7 : « cotisation et pénalité »). Jamais calculé après coup :
 * seuls des montants acceptés à l'avance rendent la créance certaine et liquide (docs/juridique/recours-legaux.md).
 */
export function calculerMontantDu(cotisationsDues: readonly number[], penaliteRetard: number): MontantDu {
  const cotisations = cotisationsDues.reduce((s, m) => s + m, 0);
  const penalites = cotisationsDues.length * penaliteRetard;
  return { cotisations, penalites, total: cotisations + penalites };
}
