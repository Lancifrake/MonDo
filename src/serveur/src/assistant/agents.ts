import type { Action, Agent, EvenementCercle, IssueAction, LigneJournal, Message, Mode, Reglement } from "./types.js";

export class Surveillance implements Agent {
  readonly nom = "surveillance" as const;
  recevoir(m: Message): Message[] {
    if (m.vers !== "surveillance") return [];
    const e: EvenementCercle = m.corps;
    if (e.type === "defaut_constate") {
      return [{ de: "surveillance", vers: "preuve", corps: { membreId: e.membreId } }];
    }
    return [{ de: "surveillance", vers: "relance", corps: { evenement: e } }];
  }
}

export class Relance implements Agent {
  readonly nom = "relance" as const;
  constructor(private readonly reglement: Reglement) {}
  recevoir(m: Message): Message[] {
    if (m.vers !== "relance") return [];
    const e = m.corps.evenement;
    let action: Action | undefined;
    if (e.type === "date_limite_proche" && this.reglement.rappelsAvantEcheanceJours.includes(e.joursRestants)) {
      action = { type: "rappel", membreId: e.membreId };
    } else if (e.type === "date_limite_depassee" && e.joursDeRetard <= this.reglement.delaiGraceJours) {
      action = { type: "rappel_retard", membreId: e.membreId };
    }
    return action ? [{ de: "relance", vers: "coordinateur", corps: { action } }] : [];
  }
}

export class Preuve implements Agent {
  readonly nom = "preuve" as const;
  constructor(private readonly reglement: Reglement) {}
  recevoir(m: Message): Message[] {
    if (m.vers !== "preuve") return [];
    if (!this.reglement.miseEnDemeureAutorisee) return [];
    const action: Action = { type: "mise_en_demeure", membreId: m.corps.membreId };
    return [{ de: "preuve", vers: "coordinateur", corps: { action } }];
  }
}

/**
 * Applique le mode : en autonome il exécute, en manuel il propose et attend l'organisateur.
 * Il vérifie toujours que l'action est autorisée par le règlement (ceinture et bretelles).
 */
export class Coordinateur implements Agent {
  readonly nom = "coordinateur" as const;
  readonly journal: LigneJournal[] = [];
  private readonly enAttente = new Map<number, Action>();
  private compteur = 0;

  constructor(
    private mode: Mode,
    private readonly reglement: Reglement,
  ) {}

  changerMode(mode: Mode): void {
    this.mode = mode;
  }

  recevoir(m: Message): Message[] {
    if (m.vers !== "coordinateur") return [];
    const { action } = m.corps;
    const numero = ++this.compteur;
    if (!this.estAutorisee(action)) {
      this.noter(numero, action, "hors_reglement");
    } else if (this.mode === "autonome") {
      this.noter(numero, action, "executee");
    } else {
      this.enAttente.set(numero, action);
      this.noter(numero, action, "en_attente");
    }
    return [];
  }

  propositionsEnAttente(): { numero: number; action: Action }[] {
    return [...this.enAttente].map(([numero, action]) => ({ numero, action }));
  }

  accepter(numero: number): void {
    this.trancher(numero, "acceptee");
  }

  refuser(numero: number): void {
    this.trancher(numero, "refusee");
  }

  private trancher(numero: number, issue: "acceptee" | "refusee"): void {
    const action = this.enAttente.get(numero);
    if (!action) throw new Error(`Aucune proposition en attente numéro ${numero}`);
    this.enAttente.delete(numero);
    this.noter(numero, action, issue);
  }

  private estAutorisee(a: Action): boolean {
    if (a.type === "mise_en_demeure") return this.reglement.miseEnDemeureAutorisee;
    return true;
  }

  private noter(numero: number, action: Action, issue: IssueAction): void {
    this.journal.push({ numero, action, issue });
  }
}
