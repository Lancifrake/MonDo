# Décision 01 : la blockchain est un registre, pas un coffre

Date : 27/10/2026. Statut : validée par David.

## Question
Rota exige un wallet USDC et une caution à l'entrée. Le PDF promet « aucun crypto côté utilisateur » et « MonDo ne détient jamais de fonds ». Comment réconcilier ?

## Options écartées
- **Wallet caché côté serveur** : MonDo garderait les clés, donc contrôlerait des fonds (contredit le pilier réglementaire), garderait la caution à l'entrée (contraire à l'objectif d'inclusion) et exigerait un passage XAF vers USDC absent du prototype.

## Décision
Reprendre la **logique** de Rota (ordre de passage, pénalités, réputation), pas son circuit de fonds.
- Les membres paient en Mobile Money (simulé au prototype). Le bénéficiaire confirme la réception.
- Le contrat est un registre de règles sans token : cercle créé, hash du règlement signé, cotisation confirmée, défaut constaté, score mis à jour.
- Ordre et pénalités calculés par contrat ou backend selon la logique reprise.
- Phase 2 : le contrat donne les ordres, le partenaire agréé exécute, sans refonte.
- Bénéfice juridique : historique horodaté et non modifiable, pièce de preuve en cas de litige (voir `docs/cadrage/problemes-tontine-traditionnelle.md`).

## Rota inspecté le 27/10 (README de `github.com/CodeWithShamim/Rota`, code non lu)
- Licence MIT, non audité, 0 étoile, 51 commits, testnet Arc (L1 de Circle, gas en USDC). Solidity 0.8.24, OpenZeppelin 5, Foundry (66 ou 74 tests selon la section du README), front Vite/React avec UI bengali.
- Contrats : `RotaFactory`, `RotaCircle` (Rota Circle et Bid Circle), `GoalPot`, `ReputationRegistry`.
- Réutilisable en logique : score de réputation (`complétions×100 + cotisations×10 + rattrapages×20 − défauts×50 − sorties anticipées×15`, plancher 0), Bid Circle (place plus tôt contre une remise redistribuée, proche de « payer des frais pour passer plus tôt »), page « Credit Passport », structure de tests (fuzz, invariants, réentrance), i18n.
- À écarter : `join()` séquestre une caution en USDC et `settleRound()` la confisque, donc le circuit de fonds qu'on refuse.
- Absent : ordre de passage par score. Rota ordonne en fixe, par tirage (blockhash, manipulable, VRF prévu) ou par enchère. C'est le cœur de MonDo et il est à écrire.
- Le PDF dit « tests repris de Rota » et « smart contracts repris de Rota » : vrai pour la réputation et les tests, faux pour l'ordre.

## Reste à vérifier
- Lire le code de `ReputationRegistry` et `RotaCircle` pour confirmer la logique et la dépendance au séquestre USDC.
- Qui confirme un paiement quand le bénéficiaire est de mauvaise foi (la confirmation humaine est l'entrée du contrat).
- Choix de la chaîne (testnet ou L2 bon marché) pour l'ancrage.
