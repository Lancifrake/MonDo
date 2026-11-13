import { Assistant } from "./assistant.js";
import type { EvenementCercle, Mode, Reglement } from "./types.js";

const REGLEMENT: Reglement = { delaiGraceJours: 2, rappelsAvantEcheanceJours: [3, 1], miseEnDemeureAutorisee: true };

/** Scénario de la démonstration : 10 membres, rappels avant l'échéance, un membre en retard puis en défaut. */
export function scenarioDeDemonstration(): EvenementCercle[] {
  const membres = Array.from({ length: 10 }, (_, i) => `m${i + 1}`);
  return [
    ...membres.map((membreId) => ({ type: "date_limite_proche" as const, membreId, joursRestants: 3 })),
    ...membres.map((membreId) => ({ type: "date_limite_proche" as const, membreId, joursRestants: 2 })),
    { type: "date_limite_depassee", membreId: "m10", joursDeRetard: 1 },
    { type: "date_limite_depassee", membreId: "m10", joursDeRetard: 3 },
    { type: "defaut_constate", membreId: "m10" },
  ];
}

export interface MesuresDuMode {
  /** Tours de distribution des messages avant que plus rien ne circule. */
  cycles: number;
  /** Charge de communication : messages échangés entre agents pour un lancement. */
  messages: number;
  dureeMoyenneMs: number;
  dureeMaxMs: number;
  /** Indéterminisme : vrai si tous les lancements donnent exactement le même journal d'actions. */
  identiques: boolean;
  /** Lignes du journal après un lancement, par issue. */
  actions: Record<string, number>;
}

export interface MesuresAssistant {
  scenario: string;
  lancements: number;
  autonome: MesuresDuMode;
  manuel: MesuresDuMode;
  memoire: {
    /** Lignes de journal gardées par un assistant après un lancement : bornée par le nombre d'événements. */
    lignesDeJournalParLancement: number;
    evenementsDuScenario: number;
    /** Chaque lancement crée ses agents et les abandonne : rien ne s'accumule d'un lancement à l'autre. */
    tasAvantOctets: number;
    tasApresOctets: number;
  };
}

function mesurerMode(mode: Mode, lancements: number): MesuresDuMode & { lignes: number } {
  let reference: string | undefined;
  let identiques = true;
  let total = 0;
  let max = 0;
  let dernier = { cycles: 0, messages: 0 };
  let actions: Record<string, number> = {};
  let lignes = 0;
  for (let i = 0; i < lancements; i++) {
    const assistant = new Assistant(mode, REGLEMENT);
    const m = assistant.traiter(scenarioDeDemonstration());
    const journal = JSON.stringify(assistant.coordinateur.journal);
    reference ??= journal;
    if (journal !== reference || (i > 0 && (m.cycles !== dernier.cycles || m.messages !== dernier.messages))) {
      identiques = false;
    }
    total += m.dureeMs;
    max = Math.max(max, m.dureeMs);
    dernier = { cycles: m.cycles, messages: m.messages };
    lignes = assistant.coordinateur.journal.length;
    actions = {};
    for (const l of assistant.coordinateur.journal) actions[l.issue] = (actions[l.issue] ?? 0) + 1;
  }
  return { ...dernier, dureeMoyenneMs: total / lancements, dureeMaxMs: max, identiques, actions, lignes };
}

/**
 * Mesures demandées par la grille d'évaluation (décision 04) : cycles et durée (cible : moins de 2 secondes),
 * nombre de messages, résultat identique d'un lancement à l'autre, mémoire. Calcul pur, sans aucune donnée.
 */
export function mesurerAssistant(lancements: number): MesuresAssistant {
  const tasAvantOctets = process.memoryUsage().heapUsed;
  const { lignes, ...autonome } = mesurerMode("autonome", lancements);
  const { lignes: _lignes, ...manuel } = mesurerMode("manuel", lancements);
  return {
    scenario: "10 membres, rappels avant l'échéance, un retard puis un défaut",
    lancements,
    autonome,
    manuel,
    memoire: {
      lignesDeJournalParLancement: lignes,
      evenementsDuScenario: scenarioDeDemonstration().length,
      tasAvantOctets,
      tasApresOctets: process.memoryUsage().heapUsed,
    },
  };
}
