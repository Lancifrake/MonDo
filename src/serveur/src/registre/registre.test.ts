import { describe, expect, it } from "vitest";
import { construireArbre, hacher, preuve, racine, verifierPreuve } from "./merkle.js";
import { ConnecteurRegistreSimule, RegistreService } from "./registre.service.js";

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
    const g = [...f]; g[3] = hacher("falsifie");
    expect(racine(g)).not.toBe(racine(f));
  });

  it("refuse un lot vide", () => {
    expect(() => construireArbre([])).toThrow();
  });
});

describe("RegistreService", () => {
  it("un million d'événements = une seule inscription par lot (ici 1000 pour 1)", async () => {
    const connecteur = new ConnecteurRegistreSimule();
    const registre = new RegistreService(connecteur);
    for (let i = 0; i < 1000; i++) registre.enregistrer(`cotisation-${i}`);
    const lot = await registre.fermerLot();
    expect(lot?.empreintes).toHaveLength(1000);
    expect(connecteur.racinesInscrites).toHaveLength(1);
  });

  it("fournit une preuve vérifiable pour chaque empreinte", async () => {
    const registre = new RegistreService(new ConnecteurRegistreSimule());
    const empreinte = registre.enregistrer("cercle c1 créé");
    for (let i = 0; i < 6; i++) registre.enregistrer(`autre-${i}`);
    await registre.fermerLot();
    const p = registre.preuvePour(empreinte)!;
    expect(verifierPreuve(empreinte, p.etapes, p.racine)).toBe(true);
  });

  it("ne ferme pas de lot vide", async () => {
    expect(await new RegistreService(new ConnecteurRegistreSimule()).fermerLot()).toBeUndefined();
  });
});
