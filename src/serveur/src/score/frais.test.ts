import { describe, expect, it } from "vitest";
import { baremeExact, calculerBareme } from "./frais.js";

describe("barème des frais du modèle A", () => {
  it("10 membres à 50 000 FCFA : 8 %, 5,33 % et 2,67 % de 450 000, moitié MonDo, moitié places de fin", () => {
    expect(calculerBareme(10, 50_000)).toEqual([
      { place: 1, frais: 36_000, partMonDo: 18_000, remiseParPlaceDeFin: 6_000 },
      { place: 2, frais: 24_000, partMonDo: 12_000, remiseParPlaceDeFin: 4_000 },
      { place: 3, frais: 12_000, partMonDo: 6_000, remiseParPlaceDeFin: 2_000 },
    ]);
  });

  it("3 membres : une seule place paie, 8 % de la cagnotte de deux cotisations", () => {
    expect(calculerBareme(3, 10_000)).toEqual([{ place: 1, frais: 1_600, partMonDo: 800, remiseParPlaceDeFin: 800 }]);
  });

  it("le milieu et la fin ne paient rien : autant de lignes que de places du début", () => {
    for (const n of [3, 4, 5, 6, 7, 10, 20, 50]) {
      const bareme = calculerBareme(n, 12_345);
      expect(bareme.map((l) => l.place)).toEqual(Array.from({ length: Math.floor(n / 3) }, (_, i) => i + 1));
    }
  });

  it("montants entiers, arrondis en faveur de celui qui paie, dégressifs, jamais plus de 8 %", () => {
    for (const n of [3, 7, 10, 11, 23, 50]) {
      for (const montant of [1, 500, 7_777, 50_000, 100_000_000]) {
        const d = Math.floor(n / 3);
        const cagnotte = (n - 1) * montant;
        let precedent = Infinity;
        for (const l of calculerBareme(n, montant)) {
          const brut = (cagnotte * 0.08 * (d + 1 - l.place)) / d;
          for (const v of [l.frais, l.partMonDo, l.remiseParPlaceDeFin]) expect(Number.isInteger(v)).toBe(true);
          expect(l.frais).toBe(l.partMonDo + d * l.remiseParPlaceDeFin);
          expect(l.frais).toBeLessThanOrEqual(brut + 1e-6);
          expect(l.partMonDo).toBeLessThanOrEqual(brut / 2 + 1e-6);
          expect(l.frais).toBeLessThanOrEqual(precedent);
          precedent = l.frais;
        }
      }
    }
  });

  it("un barème écrit à la main n'est accepté que s'il est exactement celui du calcul", () => {
    const bon = calculerBareme(10, 50_000);
    expect(baremeExact(bon, 10, 50_000)).toBe(true);
    expect(baremeExact(undefined, 10, 50_000)).toBe(false);
    expect(baremeExact(bon.slice(0, 2), 10, 50_000)).toBe(false);
    expect(baremeExact([{ ...bon[0]!, partMonDo: 17_999 }, bon[1]!, bon[2]!], 10, 50_000)).toBe(false);
    expect(baremeExact(bon, 10, 60_000)).toBe(false);
    expect(baremeExact([], 3, 10_000)).toBe(false);
  });
});
