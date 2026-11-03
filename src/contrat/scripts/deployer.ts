import { network } from "hardhat";
import { isAddress } from "viem";

/**
 * Déploie RegistreMonDo. Exemple (réseau de test seulement) :
 *   MONDO_ADMIN_ADRESSE=0x... MONDO_INSCRIPTEUR_ADRESSE=0x... pnpm hardhat run scripts/deployer.ts --network baseSepolia
 * La clé de déploiement et l'URL du nœud sont lues par Hardhat dans BASE_SEPOLIA_CLE_DEPLOIEMENT et BASE_SEPOLIA_RPC_URL.
 */
const admin = process.env.MONDO_ADMIN_ADRESSE;
const inscripteur = process.env.MONDO_INSCRIPTEUR_ADRESSE;
if (!admin || !isAddress(admin) || !inscripteur || !isAddress(inscripteur)) {
  throw new Error("MONDO_ADMIN_ADRESSE et MONDO_INSCRIPTEUR_ADRESSE doivent être des adresses valides");
}
if (admin.toLowerCase() === inscripteur.toLowerCase()) {
  throw new Error("L'administrateur et l'inscripteur doivent être deux adresses distinctes");
}

const { viem, networkName } = await network.create();
const registre = await viem.deployContract("RegistreMonDo", [admin, inscripteur]);
console.log(`RegistreMonDo déployé sur ${networkName} à l'adresse ${registre.address}`);
console.log(`Côté serveur : MONDO_REGISTRE_CONTRAT=${registre.address}`);
