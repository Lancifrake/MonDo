import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { PlanificateurService } from "./planificateur.service.js";
import { DeclencheurPlanificateur, intervallePlanificateur } from "./declencheur.js";

const MINUTE_MS = 60 * 1000;

/** Planificateur factice : compte les passages ; `bloquer` laisse un passage en cours jusqu'à `liberer()`. */
function planificateurFactice() {
  let liberer: () => void = () => {};
  const f = {
    passages: 0,
    bloquer: false,
    echouer: false,
    liberer: () => liberer(),
    examinerEcheances: vi.fn(async () => {
      f.passages++;
      if (f.echouer) throw new Error("base indisponible");
      if (f.bloquer) await new Promise<void>((r) => (liberer = r));
      return { traitees: 0, echecs: 0 };
    }),
  };
  return f;
}

let f: ReturnType<typeof planificateurFactice>;
let declencheur: DeclencheurPlanificateur;
let sms: { vider: ReturnType<typeof vi.fn<() => Promise<void>>> };
let registre: {
  ordre: string[];
  enPanne: boolean;
  reprendreInscriptions: ReturnType<typeof vi.fn<() => Promise<number>>>;
  fermerLot: ReturnType<typeof vi.fn<() => Promise<undefined>>>;
};

let purger: ReturnType<typeof vi.fn<(d: Date, f: (id: string) => Promise<boolean>) => Promise<number>>>;

beforeEach(() => {
  vi.useFakeTimers();
  f = planificateurFactice();
  sms = { vider: vi.fn(async () => {}) };
  registre = {
    ordre: [],
    enPanne: false,
    reprendreInscriptions: vi.fn(async () => {
      registre.ordre.push("reprendre");
      if (registre.enPanne) throw new Error("nœud injoignable");
      return 0;
    }),
    fermerLot: vi.fn(async () => {
      registre.ordre.push("fermer");
      return undefined;
    }),
  };
  purger = vi.fn(async (_d: Date, enCours: (id: string) => Promise<boolean>) => ((await enCours("m")) ? 0 : 2));
  declencheur = new DeclencheurPlanificateur(
    f as unknown as PlanificateurService,
    sms,
    registre,
    { purger },
    { aUnCercleEnCours: async () => false },
  );
});
afterEach(async () => {
  await declencheur.arreter();
  vi.useRealTimers();
});

describe("déclenchement régulier du planificateur", () => {
  it("un passage dès le démarrage (rattrapage après un arrêt), puis un à chaque intervalle", async () => {
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(0);
    expect(f.passages).toBe(1);
    await vi.advanceTimersByTimeAsync(60 * MINUTE_MS);
    expect(f.passages).toBe(2);
    await vi.advanceTimersByTimeAsync(120 * MINUTE_MS);
    expect(f.passages).toBe(4);
  });

  it("chaque passage relance aussi les SMS restés en file", async () => {
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(60 * MINUTE_MS);
    expect(sms.vider).toHaveBeenCalledTimes(2);
  });

  it("chaque passage réinscrit les lots en échec puis ferme le lot en cours et l'inscrit sur la chaîne", async () => {
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(60 * MINUTE_MS);
    expect(registre.ordre).toEqual(["reprendre", "fermer", "reprendre", "fermer"]);
  });

  it("chaîne en panne : le passage continue (SMS envoyés), le lot sera repris au passage suivant", async () => {
    registre.enPanne = true;
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(0);
    expect(sms.vider).toHaveBeenCalledTimes(1);
    registre.enPanne = false;
    await vi.advanceTimersByTimeAsync(60 * MINUTE_MS);
    expect(registre.fermerLot).toHaveBeenCalledTimes(1);
  });

  it("échéances en erreur : les SMS et le registre passent quand même", async () => {
    f.echouer = true;
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(0);
    expect(sms.vider).toHaveBeenCalledTimes(1);
    expect(registre.fermerLot).toHaveBeenCalledTimes(1);
  });

  it("démarré deux fois : une seule minuterie", async () => {
    declencheur.demarrer(60 * MINUTE_MS);
    declencheur.demarrer(60 * MINUTE_MS);
    await vi.advanceTimersByTimeAsync(60 * MINUTE_MS);
    expect(f.passages).toBe(2);
  });

  it("passage précédent pas fini : on n'en lance pas un second en parallèle", async () => {
    f.bloquer = true;
    declencheur.demarrer(MINUTE_MS);
    await vi.advanceTimersByTimeAsync(5 * MINUTE_MS);
    expect(f.passages).toBe(1);
    f.bloquer = false;
    f.liberer();
    await vi.advanceTimersByTimeAsync(MINUTE_MS);
    expect(f.passages).toBe(2);
  });

  it("un passage qui échoue n'arrête pas les suivants", async () => {
    f.echouer = true;
    declencheur.demarrer(MINUTE_MS);
    await vi.advanceTimersByTimeAsync(2 * MINUTE_MS);
    expect(f.passages).toBe(3);
  });

  it("arrêté : plus aucun passage, et l'arrêt attend la fin du passage en cours", async () => {
    f.bloquer = true;
    declencheur.demarrer(MINUTE_MS);
    await vi.advanceTimersByTimeAsync(0);
    let arrete = false;
    const arret = declencheur.arreter().then(() => (arrete = true));
    await vi.advanceTimersByTimeAsync(0);
    expect(arrete).toBe(false);
    f.liberer();
    await arret;
    await vi.advanceTimersByTimeAsync(10 * MINUTE_MS);
    expect(f.passages).toBe(1);
  });
});

describe("intervalle du planificateur", () => {
  it("par défaut (absente ou vide) : toutes les heures", () => {
    expect(intervallePlanificateur({})).toBe(60 * MINUTE_MS);
    expect(intervallePlanificateur({ MONDO_PLANIFICATEUR_MINUTES: "" })).toBe(60 * MINUTE_MS);
  });

  it("réglable en minutes par MONDO_PLANIFICATEUR_MINUTES", () => {
    expect(intervallePlanificateur({ MONDO_PLANIFICATEUR_MINUTES: "15" })).toBe(15 * MINUTE_MS);
  });

  it("0 : planificateur désactivé", () => {
    expect(intervallePlanificateur({ MONDO_PLANIFICATEUR_MINUTES: "0" })).toBeUndefined();
  });

  it.each(["-5", "abc", "1.5"])("valeur invalide « %s » : refusée au démarrage", (v) => {
    expect(() => intervallePlanificateur({ MONDO_PLANIFICATEUR_MINUTES: v })).toThrow(/MONDO_PLANIFICATEUR_MINUTES/);
  });
});
