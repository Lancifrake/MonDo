import { describe, expect, it } from "vitest";
import { genererRapport } from "./rapport.js";
import { SCENARIOS } from "./scenarios.js";
import { empreinteResultat, generateur, simulerScenario } from "./simulation.js";

const scenario = (nom: string) => SCENARIOS.find((s) => s.nom.startsWith(nom))!;

describe("simulateur de scénarios (cahier des charges, M15)", () => {
  it("au moins six scénarios scriptés, chacun avec sa graine", () => {
    expect(SCENARIOS.length).toBeGreaterThanOrEqual(6);
    expect(new Set(SCENARIOS.map((s) => s.graine)).size).toBe(SCENARIOS.length);
  });

  it("même graine, mêmes résultats, dix fois de suite (indéterminisme)", () => {
    for (const s of SCENARIOS) {
      for (const mode of ["mondo", "traditionnel"] as const) {
        const reference = empreinteResultat(simulerScenario(s, mode));
        for (let i = 0; i < 9; i++) expect(empreinteResultat(simulerScenario(s, mode))).toBe(reference);
      }
    }
    const a = generateur(1);
    const b = generateur(2);
    expect([a(), a()]).not.toEqual([b(), b()]);
  });

  it("tontine saine : aucun impayé, aucune perte, scores en hausse", () => {
    const r = simulerScenario(scenario("S1"), "mondo");
    expect(r.totaux).toMatchObject({ impaye: 0, pertesHonnetes: 0, defauts: 0 });
    expect(Object.values(r.scores).every((v) => v > 50)).toBe(true);
  });

  it("défaut après réception : avec MonDo le nouveau passe en dernier et n'a rien à gagner ; sans MonDo, les honnêtes perdent", () => {
    const mondo = simulerScenario(scenario("S3"), "mondo");
    expect(mondo.cycles.every((c) => c.ordre.at(-1) === "defaillant-1")).toBe(true);
    expect(mondo.totaux.pertesHonnetes).toBe(0);
    const traditionnel = simulerScenario(scenario("S3"), "traditionnel");
    expect(traditionnel.totaux.pertesHonnetes).toBeGreaterThan(0);
  });

  it("cercle de nouveaux : MonDo perd moins que la tradition, et le défaillant n'est jamais en tête", () => {
    const mondo = simulerScenario(scenario("S4"), "mondo");
    const traditionnel = simulerScenario(scenario("S4"), "traditionnel");
    for (const c of mondo.cycles) expect(c.ordre.indexOf("defaillant-1")).toBeGreaterThanOrEqual(3);
    // Limite connue : au premier cycle, personne n'a de score, et le défaillant prend encore une cagnotte.
    expect(mondo.cycles[0]!.pertesHonnetes).toBeGreaterThan(0);
    expect(mondo.totaux.pertesHonnetes).toBeLessThan(traditionnel.totaux.pertesHonnetes);
  });

  it("connus sous le seuil du début : les places de tête vont en restes et un nouveau peut y tomber (question ouverte)", () => {
    const r = simulerScenario(scenario("S7"), "mondo");
    expect(r.cycles[0]!.ordre.indexOf("defaillant-1")).toBeLessThan(3);
    expect(r.cycles[0]!.pertesHonnetes).toBeGreaterThan(0);
    // Au cycle suivant, ses premières places sont fermées : il n'est plus en tête.
    expect(r.cycles[1]!.ordre.indexOf("defaillant-1")).toBeGreaterThanOrEqual(3);
  });

  it("retards : MonDo en a moins (rappels) et ne demande aucune relance à la main ; les agents restent sous 2 secondes", () => {
    const mondo = simulerScenario(scenario("S2"), "mondo");
    const traditionnel = simulerScenario(scenario("S2"), "traditionnel");
    expect(mondo.totaux.retards).toBeLessThan(traditionnel.totaux.retards);
    expect(mondo.totaux.relancesManuelles).toBe(0);
    expect(traditionnel.totaux.relancesManuelles).toBeGreaterThan(0);
    expect(mondo.totaux.actionsAssistant).toBeGreaterThan(0);
    expect(mondo.totaux.dureeMaxDecisionMs).toBeLessThan(2000);
  });

  it("le rapport : un tableur, un résumé avec les hypothèses, trois figures pour le poster", () => {
    const r = genererRapport(SCENARIOS);
    expect(r.csv.split("\n")[0]).toMatch(/^scenario;mode;/);
    expect(r.csv.trim().split("\n")).toHaveLength(1 + 2 * SCENARIOS.length);
    expect(r.resume).toMatch(/Hypothèses/);
    expect(r.resume).toMatch(/S4-cercle-de-nouveaux/);
    expect(Object.keys(r.figures)).toHaveLength(3);
    for (const svg of Object.values(r.figures)) {
      expect(svg).toMatch(/^<svg /);
      expect(svg).toMatch(/<title>/);
    }
  });
});
