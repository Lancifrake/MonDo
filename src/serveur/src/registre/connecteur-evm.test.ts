import { describe, expect, it } from "vitest";
import { ConnecteurRegistreEvm, connecteurEvmDepuisEnvironnement, type ClientsChaine } from "./connecteur-evm.js";

function chaineFactice(statut: "success" | "reverted" = "success") {
  const inscrites = new Map<string, bigint>();
  const appels: string[] = [];
  const chaine: ClientsChaine = {
    lire: async (r) => inscrites.get(r) ?? 0n,
    inscrire: async (r) => {
      appels.push(r);
      if (statut === "success") inscrites.set(r, 1n);
      return `0x${"ab".repeat(32)}`;
    },
    attendreRecu: async () => ({ status: statut }),
  };
  return { chaine, appels };
}

describe("connecteur EVM du registre", () => {
  it("inscrit une racine et rend le hash de la transaction", async () => {
    const { chaine, appels } = chaineFactice();
    const r = await new ConnecteurRegistreEvm(chaine).inscrireRacine("cd".repeat(32));
    expect(r.referenceInscription).toBe(`0x${"ab".repeat(32)}`);
    expect(appels).toEqual([`0x${"cd".repeat(32)}`]);
  });

  it("rejouable : ne réécrit pas une racine déjà inscrite", async () => {
    const { chaine, appels } = chaineFactice();
    const connecteur = new ConnecteurRegistreEvm(chaine);
    await connecteur.inscrireRacine("cd".repeat(32));
    const deuxieme = await connecteur.inscrireRacine("cd".repeat(32));
    expect(deuxieme.referenceInscription).toMatch(/^deja-inscrite:/);
    expect(appels).toHaveLength(1);
  });

  it("échoue si la transaction est rejetée, pour que le lot reste à reprendre", async () => {
    const { chaine } = chaineFactice("reverted");
    await expect(new ConnecteurRegistreEvm(chaine).inscrireRacine("cd".repeat(32))).rejects.toThrow(/refusée/);
  });

  it("sans configuration complète, pas de connecteur réel", () => {
    expect(connecteurEvmDepuisEnvironnement({})).toBeUndefined();
    expect(connecteurEvmDepuisEnvironnement({ MONDO_REGISTRE_RPC_URL: "http://x" })).toBeUndefined();
  });

  it("refuse une adresse de contrat invalide", () => {
    expect(() =>
      connecteurEvmDepuisEnvironnement({
        MONDO_REGISTRE_RPC_URL: "http://localhost:8545",
        MONDO_REGISTRE_CONTRAT: "pas-une-adresse",
        MONDO_REGISTRE_CLE: `0x${"11".repeat(32)}`,
      }),
    ).toThrow(/adresse/);
  });
});
