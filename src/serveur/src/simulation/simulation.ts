import { Assistant } from "../assistant/assistant.js";
import type { EvenementCercle } from "../assistant/types.js";
import { attribuerLesPlaces } from "../score/attribution-des-places.js";
import type { EvenementScore } from "../score/evenements.js";
import { calculerScore, premieresPlacesFermees } from "../score/score.js";

/**
 * Simulateur de scénarios (cahier des charges, M15). Rejoue des tontines avec des profils de membres, à graine
 * fixe, avec les vraies règles de MonDo (score, attribution des places, fermeture des premières places après un
 * défaut, assistant multi-agents) et avec une tontine traditionnelle de référence. Le comportement des membres
 * est un modèle : ses hypothèses sont écrites dans `HYPOTHESES` et reprises dans le rapport.
 */

export type Profil = "bon_payeur" | "retardataire" | "solde_insuffisant" | "defaillant";
export type Mode = "mondo" | "traditionnel";

export interface MembreSimule {
  id: string;
  profil: Profil;
  /** Cycles complets et sans défaut déjà faits dans MonDo avant le scénario (0 : nouveau). */
  cyclesAnterieurs: number;
}

export interface Scenario {
  nom: string;
  description: string;
  membres: MembreSimule[];
  cycles: number;
  montant: number;
  graine: number;
}

/** Comportement supposé, par profil et par cotisation. Ce sont des hypothèses, pas des mesures. */
export const HYPOTHESES = {
  probabilites: {
    bon_payeur: { aTemps: 0.97, retard: 0.03, defaut: 0 },
    retardataire: { aTemps: 0.5, retard: 0.5, defaut: 0 },
    solde_insuffisant: { aTemps: 0.6, retard: 0.25, defaut: 0.15 },
  },
  /** Le défaillant paie tant qu'il n'a pas reçu sa cagnotte, puis cesse de payer (« défaut après réception »). */
  defaillant: "paie jusqu'à sa cagnotte, puis plus rien",
  /** Avec MonDo, les rappels avant l'échéance évitent la moitié des retards ; sans rappel, aucun. */
  retardsEvitesParLesRappels: 0.5,
  /** Tontine traditionnelle : ordre tiré au sort à chaque cycle, aucun historique, aucune exclusion. */
  ordreTraditionnel: "tirage au sort à chaque cycle",
  /** Chaque retard ou défaut demande une relance faite à la main par l'organisateur d'une tontine traditionnelle. */
  relancesManuelles: "une par retard ou défaut",
} as const;

/** Générateur pseudo-aléatoire à graine (mulberry32) : même graine, mêmes tirages. */
export function generateur(graine: number): () => number {
  let a = graine >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export interface ResultatCycle {
  cycle: number;
  ordre: string[];
  du: number;
  impaye: number;
  retards: number;
  defauts: number;
  /** Ce que les membres honnêtes (bons payeurs et retardataires) ont versé sans le recevoir en retour. */
  pertesHonnetes: number;
  relancesManuelles: number;
  actionsAssistant: number;
  messagesAgents: number;
  cyclesAgents: number;
  dureeDecisionMs: number;
}

export interface ResultatScenario {
  scenario: string;
  mode: Mode;
  cycles: ResultatCycle[];
  /** Score final par membre (MonDo seulement ; 0 pour la tontine traditionnelle, qui n'en a pas). */
  scores: Record<string, number>;
  totaux: {
    du: number;
    impaye: number;
    tauxImpayes: number;
    pertesHonnetes: number;
    retards: number;
    defauts: number;
    relancesManuelles: number;
    actionsAssistant: number;
    messagesAgents: number;
    dureeMaxDecisionMs: number;
  };
}

const honnete = (p: Profil) => p === "bon_payeur" || p === "retardataire";

function historiqueInitial(m: MembreSimule): EvenementScore[] {
  const evts: EvenementScore[] = [];
  for (let c = 0; c < m.cyclesAnterieurs; c++) {
    for (let t = 0; t < 9; t++) evts.push({ type: "cotisation_a_temps", cercleId: `avant-${c}`, date: "" });
    evts.push({ type: "cycle_termine", cercleId: `avant-${c}`, date: "" });
  }
  return evts;
}

function melanger<T>(liste: readonly T[], aleatoire: () => number): T[] {
  const copie = [...liste];
  for (let i = copie.length - 1; i > 0; i--) {
    const j = Math.floor(aleatoire() * (i + 1));
    [copie[i], copie[j]] = [copie[j]!, copie[i]!];
  }
  return copie;
}

export function simulerScenario(s: Scenario, mode: Mode): ResultatScenario {
  const aleatoire = generateur(s.graine);
  const historiques = new Map(s.membres.map((m) => [m.id, mode === "mondo" ? historiqueInitial(m) : []]));
  const parId = new Map(s.membres.map((m) => [m.id, m]));
  const resultats: ResultatCycle[] = [];

  for (let cycle = 1; cycle <= s.cycles; cycle++) {
    const cercleId = `${s.nom}-${cycle}`;
    // Ordre : par score avec MonDo (chacun demande la place 1, l'attribution tranche) ; tiré au sort sinon.
    const ordre =
      mode === "mondo"
        ? attribuerLesPlaces(
            s.membres.map((m, i) => {
              const h = historiques.get(m.id)!;
              return {
                id: m.id,
                score: calculerScore(h),
                rangInscription: i + 1,
                placeSouhaitee: 1,
                exclusDuDebut: premieresPlacesFermees(h),
              };
            }),
          ).map((p) => p.membre.id)
        : melanger(
            s.membres.map((m) => m.id),
            aleatoire,
          );

    const n = ordre.length;
    const verse = new Map(ordre.map((id) => [id, 0]));
    const recu = new Map(ordre.map((id) => [id, 0]));
    const defautCycle = new Set<string>();
    const evenementsAgents: EvenementCercle[] = [];
    let impaye = 0;
    let retards = 0;
    let defauts = 0;

    ordre.forEach((beneficiaire, indexTour) => {
      for (const payeur of ordre) {
        if (payeur === beneficiaire) continue;
        const m = parId.get(payeur)!;
        const aDejaRecu = ordre.indexOf(payeur) < indexTour;
        let issue: "aTemps" | "retard" | "defaut";
        if (m.profil === "defaillant") {
          issue = aDejaRecu ? "defaut" : "aTemps";
        } else {
          const p = HYPOTHESES.probabilites[m.profil];
          const r = aleatoire();
          issue = r < p.aTemps ? "aTemps" : r < p.aTemps + p.retard ? "retard" : "defaut";
          if (issue === "retard" && mode === "mondo" && aleatoire() < HYPOTHESES.retardsEvitesParLesRappels) {
            issue = "aTemps";
          }
        }
        evenementsAgents.push({ type: "date_limite_proche", membreId: payeur, joursRestants: 3 });
        if (issue === "defaut") {
          impaye += s.montant;
          defauts++;
          defautCycle.add(payeur);
          evenementsAgents.push({ type: "date_limite_depassee", membreId: payeur, joursDeRetard: 1 });
          evenementsAgents.push({ type: "defaut_constate", membreId: payeur });
          if (mode === "mondo") historiques.get(payeur)!.push({ type: "defaut", cercleId, date: "" });
          continue;
        }
        if (issue === "retard") {
          retards++;
          evenementsAgents.push({ type: "date_limite_depassee", membreId: payeur, joursDeRetard: 1 });
        }
        verse.set(payeur, verse.get(payeur)! + s.montant);
        recu.set(beneficiaire, recu.get(beneficiaire)! + s.montant);
        if (mode === "mondo") {
          historiques
            .get(payeur)!
            .push({ type: issue === "aTemps" ? "cotisation_a_temps" : "cotisation_en_retard", cercleId, date: "" });
        }
      }
    });
    if (mode === "mondo") {
      for (const id of ordre) {
        if (!defautCycle.has(id)) historiques.get(id)!.push({ type: "cycle_termine", cercleId, date: "" });
      }
    }

    // Les agents traitent les événements du cycle, mode autonome (les rappels partent seuls).
    const assistant = new Assistant("autonome", {
      delaiGraceJours: 2,
      rappelsAvantEcheanceJours: [3],
      miseEnDemeureAutorisee: true,
    });
    const mesure = mode === "mondo" ? assistant.traiter(evenementsAgents) : { cycles: 0, messages: 0, dureeMs: 0 };
    const pertesHonnetes = ordre
      .filter((id) => honnete(parId.get(id)!.profil))
      .reduce((total, id) => total + Math.max(0, verse.get(id)! - recu.get(id)!), 0);

    resultats.push({
      cycle,
      ordre,
      du: n * (n - 1) * s.montant,
      impaye,
      retards,
      defauts,
      pertesHonnetes,
      relancesManuelles: mode === "traditionnel" ? retards + defauts : 0,
      actionsAssistant:
        mode === "mondo" ? assistant.coordinateur.journal.filter((l) => l.issue === "executee").length : 0,
      messagesAgents: mesure.messages,
      cyclesAgents: mesure.cycles,
      dureeDecisionMs: mesure.dureeMs,
    });
  }

  const somme = (cle: keyof ResultatCycle) => resultats.reduce((t, r) => t + (r[cle] as number), 0);
  const du = somme("du");
  const impaye = somme("impaye");
  return {
    scenario: s.nom,
    mode,
    cycles: resultats,
    scores: Object.fromEntries(
      s.membres.map((m) => [m.id, mode === "mondo" ? calculerScore(historiques.get(m.id)!) : 0]),
    ),
    totaux: {
      du,
      impaye,
      tauxImpayes: du === 0 ? 0 : impaye / du,
      pertesHonnetes: somme("pertesHonnetes"),
      retards: somme("retards"),
      defauts: somme("defauts"),
      relancesManuelles: somme("relancesManuelles"),
      actionsAssistant: somme("actionsAssistant"),
      messagesAgents: somme("messagesAgents"),
      dureeMaxDecisionMs: Math.max(...resultats.map((r) => r.dureeDecisionMs)),
    },
  };
}

/** Tout sauf les durées, qui varient d'une machine à l'autre : sert à vérifier la reproductibilité. */
export const empreinteResultat = (r: ResultatScenario) =>
  JSON.stringify({
    ...r,
    cycles: r.cycles.map(({ dureeDecisionMs: _d, ...c }) => c),
    totaux: { ...r.totaux, dureeMaxDecisionMs: 0 },
  });
