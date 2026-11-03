import { createPublicClient, createWalletClient, http, isAddress, type Address, type Hex } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia } from "viem/chains";
import type { ConnecteurRegistre } from "./connecteur.js";

/** Partie de l'interface du contrat RegistreMonDo (src/contrat) dont le serveur a besoin. */
export const ABI_REGISTRE = [
  {
    type: "function",
    name: "inscrireRacine",
    stateMutability: "nonpayable",
    inputs: [{ name: "racine", type: "bytes32" }],
    outputs: [{ name: "numeroLot", type: "uint256" }],
  },
  {
    type: "function",
    name: "horodatageDe",
    stateMutability: "view",
    inputs: [{ name: "racine", type: "bytes32" }],
    outputs: [{ name: "horodatage", type: "uint64" }],
  },
] as const;

/** Ce dont le connecteur a besoin des clients viem : lire, écrire, attendre le reçu. */
export interface ClientsChaine {
  lire(racine: Hex): Promise<bigint>;
  inscrire(racine: Hex): Promise<Hex>;
  attendreRecu(hash: Hex): Promise<{ status: "success" | "reverted" }>;
}

/**
 * Inscrit les racines sur le contrat RegistreMonDo (Base Sepolia au prototype).
 * Rejouable : une racine déjà inscrite (inscription réussie mais non notée en base) n'est pas réécrite.
 */
export class ConnecteurRegistreEvm implements ConnecteurRegistre {
  constructor(private readonly chaine: ClientsChaine) {}

  async inscrireRacine(racine: string): Promise<{ referenceInscription: string }> {
    const valeur = `0x${racine}` as Hex;
    if ((await this.chaine.lire(valeur)) > 0n) return { referenceInscription: `deja-inscrite:${racine}` };
    const hash = await this.chaine.inscrire(valeur);
    const recu = await this.chaine.attendreRecu(hash);
    if (recu.status !== "success") throw new Error(`Inscription de la racine refusée par la chaîne (${hash})`);
    return { referenceInscription: hash };
  }
}

/**
 * Connecteur réel si les trois variables sont présentes, sinon undefined (le simulé prend le relais).
 * La clé n'est lue que dans l'environnement, jamais dans le dépôt (SECURITY.md).
 */
export function connecteurEvmDepuisEnvironnement(
  env: NodeJS.ProcessEnv = process.env,
): ConnecteurRegistreEvm | undefined {
  const { MONDO_REGISTRE_RPC_URL: url, MONDO_REGISTRE_CONTRAT: adresse, MONDO_REGISTRE_CLE: cle } = env;
  if (!url || !adresse || !cle) return undefined;
  if (!isAddress(adresse)) throw new Error("MONDO_REGISTRE_CONTRAT n'est pas une adresse valide");
  const account = privateKeyToAccount(cle as Hex);
  const lecture = createPublicClient({ chain: baseSepolia, transport: http(url) });
  const ecriture = createWalletClient({ chain: baseSepolia, transport: http(url), account });
  return new ConnecteurRegistreEvm(clientsViem(lecture, ecriture, adresse));
}

type Lecture = Pick<ReturnType<typeof createPublicClient>, "readContract" | "waitForTransactionReceipt">;
type Ecriture = Pick<ReturnType<typeof createWalletClient>, "writeContract" | "account" | "chain">;

export function clientsViem(lecture: Lecture, ecriture: Ecriture, adresse: Address): ClientsChaine {
  return {
    lire: (racine) =>
      lecture.readContract({ address: adresse, abi: ABI_REGISTRE, functionName: "horodatageDe", args: [racine] }),
    inscrire: (racine) =>
      ecriture.writeContract({
        address: adresse,
        abi: ABI_REGISTRE,
        functionName: "inscrireRacine",
        args: [racine],
        account: ecriture.account!,
        chain: ecriture.chain,
      }),
    attendreRecu: (hash) => lecture.waitForTransactionReceipt({ hash }),
  };
}
