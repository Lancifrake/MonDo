import { describe, expect, it } from "vitest";
import { attribuerLesPlaces, premierePlaceAutorisee, type Candidat } from "./attribution-des-places.js";

const c = (id: string, score: number, rang: number, place: number, extra: Partial<Candidat> = {}): Candidat => ({
  id,
  score,
  rangInscription: rang,
  placeSouhaitee: place,
  ...extra,
});
const ids = (cs: Candidat[]) => attribuerLesPlaces(cs).map((p) => p.membre.id);

describe("première place autorisée par le score", () => {
  // Cercle de 9 : début 1 à 3, milieu 4 à 6, fin 7 à 9.
  it("au-dessus du seuil du début : n'importe quelle place", () => {
    expect(premierePlaceAutorisee(60, 9)).toBe(1);
  });
  it("au-dessus du seuil du milieu : à partir du milieu", () => {
    expect(premierePlaceAutorisee(30, 9)).toBe(4);
    expect(premierePlaceAutorisee(59, 9)).toBe(4);
  });
  it("en dessous : seulement la fin", () => {
    expect(premierePlaceAutorisee(0, 9)).toBe(7);
    expect(premierePlaceAutorisee(29, 9)).toBe(7);
  });
  it("défaut au cycle précédent : jamais le début, même avec un bon score", () => {
    expect(premierePlaceAutorisee(90, 9, { exclusDuDebut: true })).toBe(4);
  });
  it("cercle de 3 : une place par zone", () => {
    expect([90, 40, 0].map((s) => premierePlaceAutorisee(s, 3))).toEqual([1, 2, 3]);
  });
});

describe("attribution des places à la complétion (choix de David, 08/11)", () => {
  it("chacun obtient la place souhaitée quand elle est libre et permise", () => {
    expect(ids([c("a", 90, 1, 3), c("b", 40, 2, 2), c("c", 90, 3, 1)])).toEqual(["c", "b", "a"]);
  });

  it("un bon score peut choisir de recevoir tard", () => {
    const ordre = attribuerLesPlaces([c("epargnant", 90, 1, 3), c("x", 90, 2, 1), c("y", 40, 3, 2)]);
    expect(ordre.map((p) => p.membre.id)).toEqual(["x", "y", "epargnant"]);
    expect(ordre[2]).toMatchObject({ position: 3, zone: "fin" });
  });

  it("même place demandée : le meilleur score l'obtient, l'autre prend la plus proche permise, plutôt après", () => {
    // Cercle de 6 : début 1-2, milieu 3-4, fin 5-6. Les deux veulent la 3.
    const ordre = attribuerLesPlaces([
      c("moyen", 40, 1, 3),
      c("fort", 70, 2, 3),
      c("n1", 0, 3, 6),
      c("n2", 0, 4, 5),
      c("f2", 80, 5, 1),
      c("f3", 80, 6, 2),
    ]);
    const place = (id: string) => ordre.find((p) => p.membre.id === id)!.position;
    expect(place("fort")).toBe(3);
    expect(place("moyen")).toBe(4);
  });

  it("à égalité de score, le premier inscrit l'emporte", () => {
    const ordre = attribuerLesPlaces([c("tard", 90, 2, 1), c("tot", 90, 1, 1), c("z", 90, 3, 3)]);
    expect(ordre.map((p) => p.membre.id)).toEqual(["tot", "tard", "z"]);
  });

  it("jamais plus tôt que son score, même si la place souhaitée l'est (score baissé depuis l'adhésion)", () => {
    const ordre = attribuerLesPlaces([c("tombe", 0, 1, 1), c("a", 90, 2, 2), c("b", 90, 3, 1)]);
    expect(ordre.find((p) => p.membre.id === "tombe")!.position).toBe(3);
  });

  it("cercle de nouveaux : les places de tête restantes vont aux suivants, le premier inscrit d'abord", () => {
    // Tous à 0, tous veulent la dernière place (6) : la fin (5-6) va aux deux premiers inscrits,
    // les places 1 à 4 aux autres, dans l'ordre d'inscription.
    const ordre = attribuerLesPlaces([1, 2, 3, 4, 5, 6].map((r) => c(`m${r}`, 0, r, 6)));
    expect(ordre.map((p) => p.membre.id)).toEqual(["m3", "m4", "m5", "m6", "m2", "m1"]);
  });

  it("places de tête sans candidat autorisé : au meilleur score parmi ceux qui restent", () => {
    // Cercle de 3 : personne n'a le score du début. « milieu » (40) prend la 2, puis il reste la 1 et un
    // nouveau qui voulait la 3, prise par un nouveau mieux classé (inscrit avant).
    const ordre = attribuerLesPlaces([c("milieu", 40, 3, 2), c("n1", 0, 1, 3), c("n2", 0, 2, 3)]);
    expect(ordre.map((p) => p.membre.id)).toEqual(["n2", "milieu", "n1"]);
  });

  it("déterministe : l'ordre des membres en entrée ne change rien", () => {
    const cs = [
      c("a", 70, 1, 2),
      c("b", 70, 2, 2),
      c("c", 10, 3, 3),
      c("d", 35, 4, 4),
      c("e", 0, 5, 4),
      c("f", 90, 6, 1),
    ];
    const reference = JSON.stringify(attribuerLesPlaces(cs));
    expect(JSON.stringify(attribuerLesPlaces([...cs].reverse()))).toBe(reference);
  });

  it("chaque position de 1 à N est attribuée une seule fois", () => {
    const cs = Array.from({ length: 10 }, (_, i) => c(`m${i}`, (i * 13) % 100, i + 1, (i % 3) + 1));
    expect(attribuerLesPlaces(cs).map((p) => p.position)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });
});

describe("un membre aux premières places fermées n'est jamais placé en tête, même avec les places restantes", () => {
  it("cercle où personne n'a le score du début : l'exclu ne reçoit pas une place de tête restée vide", () => {
    // 10 membres : 9 connus à 46 (milieu permis, places 4 à 10), 1 exclu après un défaut. Tous demandent la place 1.
    const connus = Array.from({ length: 9 }, (_, i) => ({
      id: `c${i + 1}`,
      score: 46,
      rangInscription: i + 2,
      placeSouhaitee: 1,
    }));
    const exclu = { id: "exclu", score: 0, rangInscription: 1, placeSouhaitee: 1, exclusDuDebut: true };
    const ordre = attribuerLesPlaces([exclu, ...connus]);
    const placeExclu = ordre.find((p) => p.membre.id === "exclu")!;
    expect(placeExclu.zone).not.toBe("debut");
    expect(ordre.slice(0, 3).every((p) => !p.membre.exclusDuDebut)).toBe(true);
    // Toujours une place par membre.
    expect(new Set(ordre.map((p) => p.membre.id)).size).toBe(10);
  });

  it("l'échange se fait avec le mieux classé qui demandait une place plus tôt, pas avec celui qui a choisi d'attendre", () => {
    const epargnant = { id: "epargnant", score: 46, rangInscription: 2, placeSouhaitee: 9 };
    const presse = { id: "presse", score: 40, rangInscription: 3, placeSouhaitee: 1 };
    const autres = Array.from({ length: 7 }, (_, i) => ({
      id: `a${i}`,
      score: 35,
      rangInscription: i + 4,
      placeSouhaitee: 1,
    }));
    const exclu = { id: "exclu", score: 0, rangInscription: 1, placeSouhaitee: 1, exclusDuDebut: true };
    const ordre = attribuerLesPlaces([exclu, epargnant, presse, ...autres]);
    expect(ordre.find((p) => p.membre.id === "epargnant")!.position).toBe(9);
    expect(ordre.find((p) => p.membre.id === "exclu")!.zone).not.toBe("debut");
  });
});
