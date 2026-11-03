import { Coordinateur, Preuve, Relance, Surveillance } from "./agents.js";
import type { Agent, EvenementCercle, Message, Mode, NomAgent, Reglement } from "./types.js";

export interface Mesures {
  /** Tours de distribution nécessaires pour que plus aucun message ne circule. */
  cycles: number;
  messages: number;
  dureeMs: number;
}

/**
 * Assistant de l'organisateur (décision 04) : quatre agents qui coopèrent par messages.
 * Il ne touche ni à l'argent, ni au score, ni à l'ordre de passage.
 */
export class Assistant {
  readonly coordinateur: Coordinateur;
  private readonly agents: Record<NomAgent, Agent>;

  constructor(mode: Mode, reglement: Reglement) {
    this.coordinateur = new Coordinateur(mode, reglement);
    this.agents = {
      surveillance: new Surveillance(),
      relance: new Relance(reglement),
      preuve: new Preuve(reglement),
      coordinateur: this.coordinateur,
    };
  }

  traiter(evenements: readonly EvenementCercle[]): Mesures {
    const debut = performance.now();
    let file: Message[] = evenements.map((corps) => ({ de: "systeme", vers: "surveillance", corps }));
    let cycles = 0;
    let messages = 0;
    while (file.length > 0) {
      cycles++;
      const suivante: Message[] = [];
      for (const m of file) {
        messages++;
        suivante.push(...this.agents[m.vers].recevoir(m));
      }
      file = suivante;
    }
    return { cycles, messages, dureeMs: performance.now() - debut };
  }
}
