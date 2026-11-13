import type { MembreSimule, Profil, Scenario } from "./simulation.js";

const membres = (liste: [Profil, number, number][]): MembreSimule[] => {
  let n = 0;
  return liste.flatMap(([profil, nombre, cyclesAnterieurs]) =>
    Array.from({ length: nombre }, () => ({ id: `${profil}-${++n}`, profil, cyclesAnterieurs })),
  );
};

/** Les scénarios scriptés (cahier des charges, sections 10 et M15 : au moins six). Graines fixes. */
export const SCENARIOS: Scenario[] = [
  {
    nom: "S1-tontine-saine",
    description: "10 bons payeurs déjà connus",
    membres: membres([["bon_payeur", 10, 1]]),
    cycles: 3,
    montant: 50_000,
    graine: 101,
  },
  {
    nom: "S2-retards",
    description: "8 bons payeurs et 2 retardataires",
    membres: membres([
      ["bon_payeur", 8, 1],
      ["retardataire", 2, 1],
    ]),
    cycles: 3,
    montant: 50_000,
    graine: 202,
  },
  {
    nom: "S3-defaut-apres-reception",
    description:
      "9 membres connus (deux cycles derrière eux) et 1 nouveau qui arrête de payer dès qu'il a reçu sa cagnotte",
    membres: membres([
      ["defaillant", 1, 0],
      ["bon_payeur", 9, 2],
    ]),
    cycles: 3,
    montant: 50_000,
    graine: 303,
  },
  {
    nom: "S4-cercle-de-nouveaux",
    description: "10 nouveaux, dont un défaillant inscrit le premier : la limite connue de MonDo",
    membres: membres([
      ["defaillant", 1, 0],
      ["bon_payeur", 9, 0],
    ]),
    cycles: 3,
    montant: 50_000,
    graine: 404,
  },
  {
    nom: "S5-mixte",
    description: "6 bons payeurs, 2 retardataires, 1 solde insuffisant, 1 défaillant nouveau",
    membres: membres([
      ["defaillant", 1, 0],
      ["bon_payeur", 6, 2],
      ["retardataire", 2, 2],
      ["solde_insuffisant", 1, 2],
    ]),
    cycles: 3,
    montant: 25_000,
    graine: 505,
  },
  {
    nom: "S6-grande-tontine",
    description: "50 membres : 40 bons payeurs, 6 retardataires, 2 soldes insuffisants, 2 défaillants nouveaux",
    membres: membres([
      ["defaillant", 2, 0],
      ["bon_payeur", 40, 2],
      ["retardataire", 6, 2],
      ["solde_insuffisant", 2, 2],
    ]),
    cycles: 2,
    montant: 10_000,
    graine: 606,
  },
  {
    nom: "S7-connus-sous-le-seuil",
    description:
      "9 membres connus mais avec un seul cycle derrière eux (score 46, sous le seuil de 60 du début) et 1 nouveau défaillant : question ouverte",
    membres: membres([
      ["defaillant", 1, 0],
      ["bon_payeur", 9, 1],
    ]),
    cycles: 3,
    montant: 50_000,
    graine: 707,
  },
];
