import { describe, expect, it } from "vitest";
import type { EvenementScore, TypeEvenementScore } from "./evenements.js";
import { calculerOrdreDePassage, type MembreCercle } from "./ordre-de-passage.js";
import { calculerScore, resumerHistorique } from "./score.js";

const ev = (...types: TypeEvenementScore[]): EvenementScore[] =>
  types.map((type) => ({ type, cercleId: "c1", date: "2026-11-03" }));

describe("calculerScore", () => {
  it("un nouveau membre commence à 0", () => {
    expect(calculerScore([])).toBe(0);
  });

  it("gagne 4 points par cotisation à temps", () => {
    expect(calculerScore(ev("cotisation_a_temps", "cotisation_a_temps"))).toBe(8);
  });

  it("ne descend jamais sous 0, même après un défaut", () => {
    expect(calculerScore(ev("cotisation_en_retard"))).toBe(0);
    expect(calculerScore(ev("cotisation_a_temps", "defaut"))).toBe(0);
  });

  it("ne dépasse jamais 100 (exemple du document : deux cycles de 10 membres)", () => {
    const cycle = [...Array(10).fill("cotisation_a_temps"), "cycle_termine"] as TypeEvenementScore[];
    expect(calculerScore(ev(...cycle))).toBe(50);
    expect(calculerScore(ev(...cycle, ...cycle))).toBe(100);
  });

  it("applique le plancher à chaque pas, pas à la fin", () => {
    // 0 -1 -> 0 ; +4 -> 4 : et non 0 -1 +4 = 3
    expect(calculerScore(ev("cotisation_en_retard", "cotisation_a_temps"))).toBe(4);
  });

  it("est reproductible : mêmes événements, même score", () => {
    const e = ev("cotisation_a_temps", "cotisation_en_retard", "defaut", "cycle_termine");
    expect(calculerScore(e)).toBe(calculerScore([...e]));
  });
});

describe("resumerHistorique", () => {
  it("distingue un nouveau d'un défaillant tombé à 0", () => {
    expect(resumerHistorique(ev())).toEqual({ cyclesTermines: 0, defauts: 0 });
    expect(resumerHistorique(ev("defaut", "cycle_termine"))).toEqual({ cyclesTermines: 1, defauts: 1 });
  });
});

const membre = (id: string, score: number, rang: number, extra: Partial<MembreCercle> = {}): MembreCercle => ({
  id,
  score,
  rangInscription: rang,
  ...extra,
});

describe("calculerOrdreDePassage", () => {
  it("place les scores élevés au début, les nouveaux à la fin", () => {
    const ordre = calculerOrdreDePassage([membre("nouveau", 0, 1), membre("sur", 90, 2), membre("moyen", 40, 3)]);
    expect(ordre.map((p) => p.membre.id)).toEqual(["sur", "moyen", "nouveau"]);
    expect(ordre.map((p) => p.zone)).toEqual(["debut", "milieu", "fin"]);
  });

  it("départage les égalités par ordre d'inscription", () => {
    const ordre = calculerOrdreDePassage([membre("b", 0, 2), membre("a", 0, 1), membre("c", 0, 3)]);
    expect(ordre.map((p) => p.membre.id)).toEqual(["a", "b", "c"]);
  });

  it("cercle de nouveaux uniquement : ordre d'inscription", () => {
    const m = Array.from({ length: 6 }, (_, i) => membre(`m${i + 1}`, 0, i + 1)).reverse();
    expect(calculerOrdreDePassage(m).map((p) => p.membre.id)).toEqual(["m1", "m2", "m3", "m4", "m5", "m6"]);
  });

  it("un score trop bas ne donne pas accès aux premières places", () => {
    const ordre = calculerOrdreDePassage([membre("a", 59, 1), membre("b", 60, 2), membre("c", 0, 3)]);
    expect(ordre[0]?.membre.id).toBe("b");
    expect(ordre[0]?.zone).toBe("debut");
  });

  it("démo : 10 membres, un défaut, exclu du début au cycle suivant", () => {
    const membres = [
      membre("m1", 100, 1),
      membre("m2", 90, 2),
      membre("m3", 85, 3),
      membre("m4", 70, 4),
      membre("m5", 55, 5),
      membre("m6", 40, 6),
      membre("m7", 30, 7),
      membre("m8", 10, 8),
      membre("m9", 0, 9),
      membre("m10", 80, 10, { exclusDuDebut: true }),
    ];
    const ordre = calculerOrdreDePassage(membres);
    const place = (id: string) => ordre.find((p) => p.membre.id === id)!;
    expect(place("m10").zone).not.toBe("debut");
    expect(ordre).toHaveLength(10);
    expect(new Set(ordre.map((p) => p.position)).size).toBe(10);
  });

  it("est déterministe : 100 lancements donnent le même ordre", () => {
    const membres = Array.from({ length: 10 }, (_, i) => membre(`m${i}`, (i * 37) % 101, i + 1));
    const reference = JSON.stringify(calculerOrdreDePassage(membres));
    for (let i = 0; i < 100; i++) {
      expect(JSON.stringify(calculerOrdreDePassage([...membres].reverse()))).toBe(reference);
    }
  });
});
