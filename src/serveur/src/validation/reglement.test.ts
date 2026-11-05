import { describe, expect, it } from "vitest";
import { schemaReglement } from "./schemas.js";

const base = {
  montant: 10000,
  frequence: "hebdomadaire",
  nombreMembres: 3,
  penaliteRetard: 500,
  delaiGraceJours: 2,
  ouvert: false,
  datePremierTour: "2026-12-05T18:00:00.000Z",
};
const valide = (extra: Record<string, unknown>) => schemaReglement.safeParse({ ...base, ...extra }).success;

describe("période du règlement, choisie par le cercle", () => {
  it("tous les N jours, de 1 à 60 (valeurs limites)", () => {
    expect(valide({ frequence: "jours", periodeJours: 1, delaiGraceJours: 0 })).toBe(true);
    expect(valide({ frequence: "jours", periodeJours: 14 })).toBe(true);
    expect(valide({ frequence: "jours", periodeJours: 60 })).toBe(true);
    expect(valide({ frequence: "jours", periodeJours: 0 })).toBe(false);
    expect(valide({ frequence: "jours", periodeJours: 61 })).toBe(false);
    expect(valide({ frequence: "jours", periodeJours: 2.5 })).toBe(false);
  });

  it("le nombre de jours accompagne « jours » et seulement lui", () => {
    expect(valide({ frequence: "jours" })).toBe(false);
    expect(valide({ frequence: "hebdomadaire", periodeJours: 7 })).toBe(false);
    expect(valide({ frequence: "mensuelle", periodeJours: 30 })).toBe(false);
  });
});

describe("le délai de grâce est plus court que la période", () => {
  it.each([
    ["hebdomadaire", undefined, 6, true],
    ["hebdomadaire", undefined, 7, false],
    ["jours", 5, 4, true],
    ["jours", 5, 5, false],
    ["jours", 1, 1, false],
    // Mensuel : le mois le plus court compte (28 jours).
    ["mensuelle", undefined, 27, true],
    ["mensuelle", undefined, 28, false],
  ] as const)("%s %s, grâce de %i jours : accepté = %s", (frequence, periodeJours, delaiGraceJours, attendu) => {
    expect(valide({ frequence, ...(periodeJours ? { periodeJours } : {}), delaiGraceJours })).toBe(attendu);
  });

  it("le refus explique la règle", () => {
    const r = schemaReglement.safeParse({ ...base, frequence: "jours", periodeJours: 5, delaiGraceJours: 5 });
    expect(r.success).toBe(false);
    expect(JSON.stringify(r.error?.issues)).toMatch(/plus court que la période/);
  });
});
