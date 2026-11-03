# Contrat du registre MonDo

`contracts/RegistreMonDo.sol` inscrit une racine d'arbre de hachage par lot d'événements (décisions 01 et 02). Aucun fonds, aucune donnée personnelle : seulement des empreintes. **Non audité : aucun usage réel avant un audit** (SECURITY.md).

## Ce que fait le contrat
- `inscrireRacine(racine)` : réservé au rôle `INSCRIPTEUR` (le serveur), une seule fois par racine, horodatée.
- `verifierInclusion(empreinte, freres, freresADroite, racine)` : n'importe qui vérifie qu'une empreinte appartient à un lot inscrit, sans faire confiance à MonDo. Même construction que le serveur (`src/serveur/src/registre/merkle.ts`), vérifiée par un test croisé.
- `suspendre` / `reprendre` : arrêt d'urgence par l'administrateur, qui peut aussi retirer le rôle d'inscripteur (clé compromise).
- Refuse tout envoi d'argent.
- Briques OpenZeppelin : `AccessControl`, `Pausable`.

## Commandes
```bash
corepack pnpm install
corepack pnpm qualite
```

## Déployer sur Base Sepolia (réseau de test)
Non fait : il faut une clé de déploiement financée en ETH de test, qui ne doit jamais entrer dans le dépôt.
```bash
export BASE_SEPOLIA_RPC_URL=...            # nœud Base Sepolia
export BASE_SEPOLIA_CLE_DEPLOIEMENT=...    # clé du portefeuille de déploiement (test uniquement)
MONDO_ADMIN_ADRESSE=0x... MONDO_INSCRIPTEUR_ADRESSE=0x... corepack pnpm hardhat run scripts/deployer.ts --network baseSepolia
```
Côté serveur, le connecteur réel s'active avec `MONDO_REGISTRE_RPC_URL`, `MONDO_REGISTRE_CONTRAT` et `MONDO_REGISTRE_CLE` (clé du compte inscripteur). Sans elles, le registre est simulé, ce qui est refusé en production.
