export const CONNECTEUR_MOBILE_MONEY = Symbol("CONNECTEUR_MOBILE_MONEY");

export type Operateur = "orange_money" | "mtn_momo";
export type IssueSimulee = "reussi" | "echoue" | "en_retard";

/** Réponse de l'opérateur à une demande de paiement : tout de suite, ou plus tard (`retourDansMs`). */
export interface ReponseOperateur {
  referenceOperateur: string;
  retour?: { statut: "reussi" | "echoue"; motif?: string };
  retourDansMs?: number;
}

/**
 * Opérateur Mobile Money (Orange Money, MTN MoMo). Le paiement va directement du payeur au bénéficiaire :
 * MonDo ne détient jamais les fonds, il reçoit seulement le retour de l'opérateur. Au prototype, opérateur
 * simulé (cahier des charges, M4) ; un vrai branchement demandera un partenaire agréé (phase 2).
 */
export interface ConnecteurMobileMoney {
  demanderPaiement(d: { operateur: Operateur; montant: number; issue: IssueSimulee }): Promise<ReponseOperateur>;
}

/** Délai de réponse d'un opérateur « en retard », dans la simulation. */
export const RETARD_OPERATEUR_MS = 60 * 60 * 1000;

let suivant = 0;

/** Les trois issues du cahier des charges : réussi, échoué (solde insuffisant), réponse en retard. */
export class ConnecteurMobileMoneySimule implements ConnecteurMobileMoney {
  async demanderPaiement(d: { operateur: Operateur; issue: IssueSimulee }): Promise<ReponseOperateur> {
    const prefixe = d.operateur === "orange_money" ? "OM" : "MOMO";
    const referenceOperateur = `${prefixe}-SIM-${Date.now().toString(36).toUpperCase()}${String(++suivant).padStart(3, "0")}`;
    if (d.issue === "en_retard") return { referenceOperateur, retourDansMs: RETARD_OPERATEUR_MS };
    return {
      referenceOperateur,
      retour: d.issue === "reussi" ? { statut: "reussi" } : { statut: "echoue", motif: "Solde insuffisant (simulé)" },
    };
  }
}
