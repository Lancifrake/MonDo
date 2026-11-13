// Chaîne locale pour la démonstration : démarre un nœud Hardhat sur l'ordinateur, y déploie RegistreMonDo et
// affiche les variables à donner au serveur. Aucun réseau public, aucun argent : les comptes sont ceux, publics,
// de la phrase de test de Hardhat. Ctrl+C arrête le nœud (et efface la chaîne, qui ne vit qu'en mémoire).
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { createPublicClient, createWalletClient, http } from "viem";
import { mnemonicToAccount } from "viem/accounts";
import { hardhat } from "viem/chains";

const ADRESSE_NOEUD = "http://127.0.0.1:8545";
// Phrase de test publique de Hardhat : ces comptes n'ont de valeur que sur une chaîne locale.
const PHRASE_DE_TEST = "test test test test test test test test test test test junk";
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

const noeud = spawn("node_modules/.bin/hardhat", ["node"], { stdio: ["ignore", "ignore", "inherit"] });
const arreter = () => noeud.kill("SIGINT");
process.on("SIGINT", arreter);
process.on("SIGTERM", arreter);
// Une erreur pendant le déploiement ne doit pas laisser un nœud orphelin.
process.on("uncaughtException", (e) => {
  console.error(e);
  arreter();
  process.exit(1);
});

const lecture = createPublicClient({ chain: hardhat, transport: http(ADRESSE_NOEUD) });
for (let i = 0; ; i++) {
  try {
    await lecture.getChainId();
    break;
  } catch {
    if (i > 60) throw new Error("Le nœud Hardhat ne répond pas sur " + ADRESSE_NOEUD);
    await attendre(500);
  }
}

const admin = mnemonicToAccount(PHRASE_DE_TEST, { addressIndex: 0 });
const inscripteur = mnemonicToAccount(PHRASE_DE_TEST, { addressIndex: 1 });
const artefact = JSON.parse(
  await readFile(new URL("../artifacts/contracts/RegistreMonDo.sol/RegistreMonDo.json", import.meta.url), "utf8"),
);
const ecriture = createWalletClient({ chain: hardhat, transport: http(ADRESSE_NOEUD), account: admin });
const hash = await ecriture.deployContract({
  abi: artefact.abi,
  bytecode: artefact.bytecode,
  args: [admin.address, inscripteur.address],
});
const { contractAddress } = await lecture.waitForTransactionReceipt({ hash });
const cle = `0x${Buffer.from(inscripteur.getHdKey().privateKey).toString("hex")}`;

console.log(`\nRegistreMonDo déployé sur la chaîne locale à l'adresse ${contractAddress}.`);
console.log("Lancer le serveur avec (depuis src/serveur, hors production) :\n");
console.log(
  `MONDO_REGISTRE_RESEAU=local MONDO_REGISTRE_RPC_URL=${ADRESSE_NOEUD} MONDO_REGISTRE_CONTRAT=${contractAddress} ` +
    `MONDO_REGISTRE_CLE=${cle} corepack pnpm start\n`,
);
console.log("Nœud en marche. Ctrl+C pour l'arrêter.");
