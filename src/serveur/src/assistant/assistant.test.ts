import { describe, expect, it } from "vitest";
import { Assistant } from "./assistant.js";
import type { EvenementCercle, Reglement } from "./types.js";

const reglement: Reglement = { delaiGraceJours: 2, rappelsAvantEcheanceJours: [3, 1], miseEnDemeureAutorisee: true };

// Scénario de démo : 10 membres, un défaut (m10).
function scenario(): EvenementCercle[] {
  const membres = Array.from({ length: 10 }, (_, i) => `m${i + 1}`);
  return [
    ...membres.map((membreId) => ({ type: "date_limite_proche" as const, membreId, joursRestants: 3 })),
    ...membres.map((membreId) => ({ type: "date_limite_proche" as const, membreId, joursRestants: 2 })),
    { type: "date_limite_depassee", membreId: "m10", joursDeRetard: 1 },
    { type: "date_limite_depassee", membreId: "m10", joursDeRetard: 3 },
    { type: "defaut_constate", membreId: "m10" },
  ];
}

describe("assistant, mode autonome", () => {
  it("exécute les actions prévues par le règlement et seulement elles", () => {
    const a = new Assistant("autonome", reglement);
    a.traiter(scenario());
    const executees = a.coordinateur.journal.filter((l) => l.issue === "executee");
    expect(executees.filter((l) => l.action.type === "rappel")).toHaveLength(10); // jours restants 3, pas 2
    expect(executees.filter((l) => l.action.type === "rappel_retard")).toHaveLength(1); // retard 1 oui, 3 non
    expect(executees.filter((l) => l.action.type === "mise_en_demeure")).toHaveLength(1);
  });

  it("n'invente pas de mise en demeure si le règlement ne la prévoit pas", () => {
    const a = new Assistant("autonome", { ...reglement, miseEnDemeureAutorisee: false });
    a.traiter(scenario());
    expect(a.coordinateur.journal.some((l) => l.action.type === "mise_en_demeure")).toBe(false);
  });
});

describe("assistant, mode manuel", () => {
  it("ne fait rien tant que l'organisateur n'a pas accepté", () => {
    const a = new Assistant("manuel", reglement);
    a.traiter(scenario());
    expect(a.coordinateur.journal.some((l) => l.issue === "executee")).toBe(false);
    expect(a.coordinateur.propositionsEnAttente()).toHaveLength(12);
  });

  it("accepter exécute, refuser écarte", () => {
    const a = new Assistant("manuel", reglement);
    a.traiter([{ type: "defaut_constate", membreId: "m10" }, { type: "date_limite_proche", membreId: "m1", joursRestants: 1 }]);
    const [p1, p2] = a.coordinateur.propositionsEnAttente();
    a.coordinateur.accepter(p1!.numero);
    a.coordinateur.refuser(p2!.numero);
    expect(a.coordinateur.journal.map((l) => l.issue)).toEqual(["en_attente", "en_attente", "acceptee", "refusee"]);
    expect(a.coordinateur.propositionsEnAttente()).toHaveLength(0);
    expect(() => a.coordinateur.accepter(999)).toThrow();
  });
});

describe("mesures pour la grille d'évaluation", () => {
  it("un tour complet se traite en moins de 2 secondes", () => {
    const m = new Assistant("autonome", reglement).traiter(scenario());
    expect(m.dureeMs).toBeLessThan(2000);
  });

  it("charge de communication connue : événements puis messages entre agents", () => {
    const m = new Assistant("autonome", reglement).traiter(scenario());
    expect(m.cycles).toBe(3); // système -> surveillance -> relance/preuve -> coordinateur
    // 23 événements, 23 messages de la surveillance, 12 actions proposées au coordinateur
    expect(m.messages).toBe(23 + 23 + 12);
  });

  it("indéterminisme : 100 lancements du même scénario donnent le même résultat", () => {
    const resultats = new Set<string>();
    for (let i = 0; i < 100; i++) {
      const a = new Assistant("autonome", reglement);
      const m = a.traiter(scenario());
      resultats.add(JSON.stringify({ j: a.coordinateur.journal, c: m.cycles, n: m.messages }));
    }
    expect(resultats.size).toBe(1);
  });
});
