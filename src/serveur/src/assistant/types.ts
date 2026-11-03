export type Mode = "autonome" | "manuel";

/** Ce que le règlement signé du cercle autorise. Un agent n'agit jamais en dehors. */
export interface Reglement {
  delaiGraceJours: number;
  /** Jours avant la date limite où un rappel est prévu. */
  rappelsAvantEcheanceJours: readonly number[];
  miseEnDemeureAutorisee: boolean;
}

export type EvenementCercle =
  | { type: "date_limite_proche"; membreId: string; joursRestants: number }
  | { type: "date_limite_depassee"; membreId: string; joursDeRetard: number }
  | { type: "defaut_constate"; membreId: string };

export type TypeAction = "rappel" | "rappel_retard" | "mise_en_demeure";

export interface Action {
  type: TypeAction;
  membreId: string;
}

export type NomAgent = "surveillance" | "relance" | "preuve" | "coordinateur";

export type Message =
  | { de: "systeme" | NomAgent; vers: "surveillance"; corps: EvenementCercle }
  | { de: "surveillance"; vers: "relance"; corps: { evenement: EvenementCercle } }
  | { de: "surveillance"; vers: "preuve"; corps: { membreId: string } }
  | { de: "relance" | "preuve"; vers: "coordinateur"; corps: { action: Action } };

export interface Agent {
  nom: NomAgent;
  recevoir(message: Message): Message[];
}

export type IssueAction = "executee" | "en_attente" | "acceptee" | "refusee" | "hors_reglement";

export interface LigneJournal {
  numero: number;
  action: Action;
  issue: IssueAction;
}
