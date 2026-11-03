import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { network } from "hardhat";
import { hacher, preuve, racine } from "../../serveur/src/registre/merkle.js";

const hex = (h: string) => `0x${h}` as const;

async function deployer() {
  const { viem } = await network.create();
  const [admin, serveur, intrus] = await viem.getWalletClients();
  const registre = await viem.deployContract("RegistreMonDo", [admin!.account.address, serveur!.account.address]);
  return { viem, registre, admin: admin!, serveur: serveur!, intrus: intrus! };
}

describe("RegistreMonDo", () => {
  it("le serveur inscrit une racine, horodatée", async () => {
    const { registre, serveur } = await deployer();
    const r = hex(racine([hacher("a"), hacher("b")]));
    await registre.write.inscrireRacine([r], { account: serveur.account });
    assert.ok((await registre.read.horodatageDe([r])) > 0n);
    assert.equal(await registre.read.nombreDeLots(), 1n);
  });

  it("un compte sans le rôle d'inscripteur ne peut pas inscrire", async () => {
    const { registre, intrus } = await deployer();
    await assert.rejects(
      registre.write.inscrireRacine([hex(hacher("x"))], { account: intrus.account }),
      /AccessControlUnauthorizedAccount/,
    );
  });

  it("une racine ne s'inscrit qu'une fois, et jamais une racine nulle", async () => {
    const { registre, serveur } = await deployer();
    const r = hex(hacher("lot"));
    await registre.write.inscrireRacine([r], { account: serveur.account });
    await assert.rejects(registre.write.inscrireRacine([r], { account: serveur.account }), /RacineDejaInscrite/);
    await assert.rejects(
      registre.write.inscrireRacine([`0x${"0".repeat(64)}`], { account: serveur.account }),
      /RacineNulle/,
    );
  });

  it("l'administrateur peut suspendre les inscriptions, personne d'autre", async () => {
    const { registre, admin, serveur, intrus } = await deployer();
    await assert.rejects(registre.write.suspendre({ account: intrus.account }), /AccessControlUnauthorizedAccount/);
    await registre.write.suspendre({ account: admin.account });
    await assert.rejects(
      registre.write.inscrireRacine([hex(hacher("y"))], { account: serveur.account }),
      /EnforcedPause/,
    );
    await registre.write.reprendre({ account: admin.account });
    await registre.write.inscrireRacine([hex(hacher("y"))], { account: serveur.account });
  });

  it("l'administrateur peut retirer le rôle au serveur (clé compromise)", async () => {
    const { registre, admin, serveur } = await deployer();
    const role = await registre.read.INSCRIPTEUR();
    await registre.write.revokeRole([role, serveur.account.address], { account: admin.account });
    await assert.rejects(
      registre.write.inscrireRacine([hex(hacher("z"))], { account: serveur.account }),
      /AccessControlUnauthorizedAccount/,
    );
  });

  it("vérifie sur la chaîne les preuves calculées par le serveur MonDo", async () => {
    const { registre, serveur } = await deployer();
    const feuilles = ["règlement", "engagement 1", "engagement 2", "ordre", "mise en demeure"].map((c) => hacher(c));
    const r = racine(feuilles);
    await registre.write.inscrireRacine([hex(r)], { account: serveur.account });
    for (let i = 0; i < feuilles.length; i++) {
      const etapes = preuve(feuilles, i);
      const ok = await registre.read.verifierInclusion([
        hex(feuilles[i]!),
        etapes.map((e) => hex(e.frere)),
        etapes.map((e) => e.cote === "droite"),
        hex(r),
      ]);
      assert.equal(ok, true, `feuille ${i}`);
    }
    const etapes = preuve(feuilles, 0);
    const falsifiee = await registre.read.verifierInclusion([
      hex(hacher("faux document")),
      etapes.map((e) => hex(e.frere)),
      etapes.map((e) => e.cote === "droite"),
      hex(r),
    ]);
    assert.equal(falsifiee, false);
  });

  it("une preuve contre une racine non inscrite est rejetée", async () => {
    const { registre } = await deployer();
    const feuilles = [hacher("a"), hacher("b")];
    const etapes = preuve(feuilles, 0);
    const ok = await registre.read.verifierInclusion([
      hex(feuilles[0]!),
      etapes.map((e) => hex(e.frere)),
      etapes.map((e) => e.cote === "droite"),
      hex(racine(feuilles)),
    ]);
    assert.equal(ok, false);
  });

  it("une preuve mal formée est refusée", async () => {
    const { registre } = await deployer();
    await assert.rejects(
      registre.read.verifierInclusion([hex(hacher("a")), [hex(hacher("b"))], [], hex(hacher("r"))]),
      /PreuveMalFormee/,
    );
  });

  it("le contrat refuse tout envoi d'argent (MonDo ne détient jamais de fonds)", async () => {
    const { registre, admin } = await deployer();
    await assert.rejects(admin.sendTransaction({ to: registre.address, value: 1n }));
  });
});
