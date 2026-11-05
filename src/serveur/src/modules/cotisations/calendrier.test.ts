import { describe, expect, it } from "vitest";
import { calendrierDesTours } from "./calendrier.js";

const ordre = ["awa", "paul", "luc"];
const JOUR = 24 * 60 * 60 * 1000;

describe("calendrier des tours", () => {
  it("un tour par membre, dans l'ordre de passage, une semaine d'écart en hebdomadaire", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "hebdomadaire",
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-11-20T10:00:00.000Z",
    });
    expect(tours).toEqual([
      { numero: 1, beneficiaireId: "awa", dateLimite: "2026-12-05T18:00:00.000Z" },
      { numero: 2, beneficiaireId: "paul", dateLimite: "2026-12-12T18:00:00.000Z" },
      { numero: 3, beneficiaireId: "luc", dateLimite: "2026-12-19T18:00:00.000Z" },
    ]);
  });

  it("mensuel : même jour chaque mois", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "mensuelle",
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-11-20T10:00:00.000Z",
    });
    expect(tours.map((t) => t.dateLimite)).toEqual([
      "2026-12-05T18:00:00.000Z",
      "2027-01-05T18:00:00.000Z",
      "2027-02-05T18:00:00.000Z",
    ]);
  });

  it("mensuel le 31 : dernier jour des mois plus courts, sans dériver ensuite (valeur limite)", () => {
    const tours = calendrierDesTours({
      ordre: ["a", "b", "c", "d"],
      frequence: "mensuelle",
      datePremierTour: "2027-01-31T18:00:00.000Z",
      completLe: "2027-01-10T10:00:00.000Z",
    });
    expect(tours.map((t) => t.dateLimite)).toEqual([
      "2027-01-31T18:00:00.000Z",
      "2027-02-28T18:00:00.000Z",
      "2027-03-31T18:00:00.000Z",
      "2027-04-30T18:00:00.000Z",
    ]);
  });

  it("cercle complet après la date du premier tour : départ décalé d'une période", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "hebdomadaire",
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-12-07T09:00:00.000Z",
    });
    expect(tours[0]!.dateLimite).toBe("2026-12-12T18:00:00.000Z");
  });

  it("décalé d'autant de périodes qu'il faut, jamais dans le passé", () => {
    const completLe = new Date(Date.parse("2026-12-05T18:00:00.000Z") + 20 * JOUR).toISOString();
    const tours = calendrierDesTours({
      ordre,
      frequence: "hebdomadaire",
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe,
    });
    expect(tours[0]!.dateLimite).toBe("2026-12-26T18:00:00.000Z");
    expect(Date.parse(tours[0]!.dateLimite)).toBeGreaterThan(Date.parse(completLe));
  });

  it("complet pile à l'heure du premier tour : décalé, personne n'a eu le temps de payer (valeur limite)", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "hebdomadaire",
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-12-05T18:00:00.000Z",
    });
    expect(tours[0]!.dateLimite).toBe("2026-12-12T18:00:00.000Z");
  });

  it("tous les N jours : la période choisie par le cercle, ici 5 jours", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "jours",
      periodeJours: 5,
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-11-20T10:00:00.000Z",
    });
    expect(tours.map((t) => t.dateLimite)).toEqual([
      "2026-12-05T18:00:00.000Z",
      "2026-12-10T18:00:00.000Z",
      "2026-12-15T18:00:00.000Z",
    ]);
  });

  it("tous les jours (N = 1, valeur limite) et décalage d'une seule journée si le cercle se complète en retard", () => {
    const tours = calendrierDesTours({
      ordre,
      frequence: "jours",
      periodeJours: 1,
      datePremierTour: "2026-12-05T18:00:00.000Z",
      completLe: "2026-12-05T20:00:00.000Z",
    });
    expect(tours.map((t) => t.dateLimite)).toEqual([
      "2026-12-06T18:00:00.000Z",
      "2026-12-07T18:00:00.000Z",
      "2026-12-08T18:00:00.000Z",
    ]);
  });
});
