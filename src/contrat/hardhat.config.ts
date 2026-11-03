import hardhatNodeTestRunner from "@nomicfoundation/hardhat-node-test-runner";
import hardhatViem from "@nomicfoundation/hardhat-viem";
import hardhatViemAssertions from "@nomicfoundation/hardhat-viem-assertions";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatViem, hardhatNodeTestRunner, hardhatViemAssertions],
  solidity: {
    version: "0.8.28",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    // Réseau de test Base Sepolia (décision 03). La clé de déploiement n'est jamais dans le dépôt :
    // elle est lue dans l'environnement au moment du déploiement.
    baseSepolia: {
      type: "http",
      chainType: "op",
      url: configVariable("BASE_SEPOLIA_RPC_URL"),
      accounts: [configVariable("BASE_SEPOLIA_CLE_DEPLOIEMENT")],
    },
  },
});
