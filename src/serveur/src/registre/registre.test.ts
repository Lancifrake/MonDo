import { describe, expect, it } from "vitest";
import { construireArbre, hacher, preuve, racine, verifierPreuve } from "./merkle.js";
import { ConnecteurRegistreSimule, RegistreService } from "./registre.service.js";
import { baseDeTest } from "../testing/base.js";

const feuilles = (n: number) => Array.from({ length: n }, (_, i) => hacher(`evenement-${i}`));

describe("arbre de hachage", () => {
  it.each([1, 2, 3, 5, 8, 13])("chaque feuille d'un lot de %i est prouvable", (n) => {
    const f = feuilles(n);
    const r = racine(f);
    for (let i = 0; i < n; i++) expect(verifierPreuve(f[i]!, preuve(f, i), r)).toBe(true);
  });

  it("une empreinte étrangère au lot est rejetée", () => {
    const f = feuilles(6);
    expect(verifierPreuve(hacher("autre"), preuve(f, 2), racine(f))).toBe(false);
  });

  it("modifier une feuille change la racine", () => {
    const f = feuilles(6);
    const g = [...f];
    g[3] = hacher("falsifie");
    expect(racine(g)).not.toBe(racine(f));
  });

  it("sécurité : un nœud interne ne peut pas se faire passer pour une feuille", () => {
    const f = feuilles(4);
    const niveaux = construireArbre(f);
    const noeudInterne = niveaux[1]![0]!;
    const frere = niveaux[1]![1]!;
    expect(verifierPreuve(noeudInterne, [{ frere, cote: "droite" }], racine(f))).toBe(false);
  });

  it("sécurité : dupliquer la dernière feuille ne donne pas la même racine", () => {
    const [a, b, c] = feuilles(3) as [string, string, string];
    expect(racine([a, b, c])).not.toBe(racine([a, b, c, c]));
  });

  it("refuse un lot vide", () => {
    expect(() => construireArbre([])).toThrow();
  });
});

describe("RegistreService", () => {
  async function registre(connecteur = new ConnecteurRegistreSimule()) {
    return { connecteur, service: new RegistreService(connecteur, await baseDeTest()) };
  }

  it("mille événements = une seule inscription sur la chaîne", async () => {
    const { connecteur, service } = await registre();
    for (let i = 0; i < 1000; i++) await service.enregistrer(`cotisation-${i}`);
    const lot = await service.fermerLot();
    expect(lot?.empreintes).toHaveLength(1000);
    expect(connecteur.racinesInscrites).toHaveLength(1);
  });

  it("fournit une preuve vérifiable pour chaque empreinte", async () => {
    const { service } = await registre();
    const empreinte = await service.enregistrer("cercle c1 créé");
    for (let i = 0; i < 6; i++) await service.enregistrer(`autre-${i}`);
    await service.fermerLot();
    const p = (await service.preuvePour(empreinte))!;
    expect(verifierPreuve(empreinte, p.etapes, p.racine)).toBe(true);
  });

  it("ne ferme pas de lot vide et ne prouve pas une empreinte pas encore inscrite", async () => {
    const { service } = await registre();
    expect(await service.fermerLot()).toBeUndefined();
    const e = await service.enregistrer("en attente");
    expect(await service.preuvePour(e)).toBeUndefined();
  });

  it("fiabilité : si la chaîne est en panne, le lot attend et part à la reprise", async () => {
    let enPanne = true;
    const connecteur = new ConnecteurRegistreSimule();
    const fragile = {
      racinesInscrites: connecteur.racinesInscrites,
      inscrireRacine: async (r: string) => {
        if (enPanne) throw new Error("réseau indisponible");
        return connecteur.inscrireRacine(r);
      },
    };
    const service = new RegistreService(fragile, await baseDeTest());
    await service.enregistrer("a");
    await expect(service.fermerLot()).rejects.toThrow("réseau indisponible");
    expect(connecteur.racinesInscrites).toHaveLength(0);
    enPanne = false;
    expect(await service.reprendreInscriptions()).toBe(1);
    expect(connecteur.racinesInscrites).toHaveLength(1);
    expect(await service.reprendreInscriptions()).toBe(0);
  });
});
