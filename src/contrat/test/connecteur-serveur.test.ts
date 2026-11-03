import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { network } from "hardhat";
import { ConnecteurRegistreEvm, clientsViem } from "../../serveur/src/registre/connecteur-evm.js";
import { hacher, preuve, racine } from "../../serveur/src/registre/merkle.js";

describe("serveur MonDo et contrat, de bout en bout", () => {
  it("le connecteur du serveur inscrit la racine d'un lot, vérifiable sur la chaîne", async () => {
    const { viem } = await network.create();
    const [admin, serveur] = await viem.getWalletClients();
    const registre = await viem.deployContract("RegistreMonDo", [admin!.account.address, serveur!.account.address]);
    const lecture = await viem.getPublicClient();
    const connecteur = new ConnecteurRegistreEvm(clientsViem(lecture, serveur!, registre.address));

    const feuilles = ["cotisation 1", "cotisation 2", "défaut"].map((c) => hacher(c));
    const r = racine(feuilles);
    const premiere = await connecteur.inscrireRacine(r);
    assert.match(premiere.referenceInscription, /^0x[0-9a-f]{64}$/);

    // Rejeu après une panne côté serveur : pas de seconde transaction, pas d'erreur.
    const rejeu = await connecteur.inscrireRacine(r);
    assert.match(rejeu.referenceInscription, /^deja-inscrite:/);
    assert.equal(await registre.read.nombreDeLots(), 1n);

    const etapes = preuve(feuilles, 2);
    const ok = await registre.read.verifierInclusion([
      `0x${feuilles[2]}`,
      etapes.map((e) => `0x${e.frere}` as const),
      etapes.map((e) => e.cote === "droite"),
      `0x${r}`,
    ]);
    assert.equal(ok, true);
  });

  it("un connecteur sans le rôle d'inscripteur échoue, le lot reste à reprendre", async () => {
    const { viem } = await network.create();
    const [admin, serveur, intrus] = await viem.getWalletClients();
    const registre = await viem.deployContract("RegistreMonDo", [admin!.account.address, serveur!.account.address]);
    const connecteur = new ConnecteurRegistreEvm(clientsViem(await viem.getPublicClient(), intrus!, registre.address));
    await assert.rejects(connecteur.inscrireRacine(hacher("lot")), /AccessControlUnauthorizedAccount/);
  });
});
