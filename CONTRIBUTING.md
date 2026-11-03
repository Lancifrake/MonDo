# Contribuer à MonDo

Ce guide fixe les règles de travail de l'équipe. Il évoluera avec le code : tout changement de règle passe par une pull request, comme le reste.

## Avant de commencer
1. Lire le [README](README.md) et les décisions de `docs/conception/` (01 à 03).
2. Lire [SECURITY.md](SECURITY.md) : certaines règles s'appliquent à chaque commit.

## Langue
Le français est la langue de travail : documents, issues, pull requests, messages de commit. Le code (noms de variables, de fonctions et de types) suit le vocabulaire du domaine défini dans les documents (Cercle, Cotisation, Score…), pour que tout le monde parle des mêmes objets.

## Branches
- `main` est toujours dans un état présentable. **On n'y pousse jamais directement : tout passe par une pull request.**
- Une branche par sujet, nommée `type/sujet-court`, par exemple `feat/calcul-score` ou `docs/flow-litige`.
- Une branche vit peu de temps : on la fusionne vite, on la supprime ensuite.

## Commits
Format : `type: description courte à l'impératif ou au présent`.

| Type | Quand |
|---|---|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction d'un défaut |
| `docs` | documentation, schémas, décisions |
| `chore` | outillage, configuration, dépendances, rangement |

Règles :
- Un commit = un changement compréhensible seul.
- Pas de co-auteur dans le message.
- Pas de fichier généré, de sauvegarde d'éditeur ni de secret (voir `.gitignore`).

## Pull requests
1. Une pull request par étape terminée, contre `main`, avec le modèle fourni : **ce qui change et pourquoi**, comment le vérifier, ce qui n'est pas fait.
2. `pnpm qualite` passe en local avant d'ouvrir la pull request, et l'intégration continue passe avant la fusion.
3. **L'auteur fusionne lui-même** dès que l'étape est terminée, sans attendre de relecture. On fusionne par commit de fusion (pas de « squash ») pour garder chaque commit dans l'historique.
4. **Relecture après coup** : chacun relit les pull requests fusionnées des autres et commente sur GitHub. Un problème trouvé devient une nouvelle pull request de correction (`fix:`), jamais une réécriture de `main`.
5. Une pull request reste petite. Au-delà d'environ 400 lignes de code, on la découpe.
6. Exception : une décision de conception ou une règle métier nouvelle n'est pas fusionnée sans l'accord de l'équipe (voir ci-dessous).

## Décisions de conception
Un choix qui engage le projet (technologie, règle métier, architecture) s'écrit dans `docs/conception/decision-NN-sujet.md` : question, options, décision, conséquences, statut. La numérotation continue. Une décision n'est « validée » qu'avec l'accord explicite de l'équipe.

## Fichiers qui font foi
- User flows : `docs/conception/userflows/mondo-userflows.drawio`. Les versions Mermaid, PNG et SVG sont gelées depuis le 27/10/2026.
- Architecture : `docs/conception/architecture/mondo-architecture.excalidraw`.
- Cas d'utilisation : `docs/conception/cas-d-utilisation/User-Case.vpp`.
- Les images d'aperçu (PNG) sont des références, pas des sources : on ne les modifie pas à la main.

## Code (dès que `src/` existe)
- TypeScript partout, mode strict.
- Le serveur suit la [décision 02](docs/conception/decision-02-monolithe-modulaire.md) : **chaque module ne lit et n'écrit que ses propres tables** ; les modules communiquent par interfaces et par événements.
- Les connecteurs externes (SMS, Mobile Money, vérification d'identité, registre) restent derrière des interfaces, simulés au prototype.
- Toute règle métier (score, délais, pénalités) est couverte par des tests. Le score est la somme d'événements, jamais une valeur écrite à la main.
- Outils : `corepack enable` une fois (ou préfixer par `corepack`), puis dans `src/serveur` : `pnpm install`, `pnpm test`, `pnpm qualite` (lint, types, format, couverture). `pnpm qualite` doit passer avant toute pull request. Voir [la stratégie de test](docs/conception/strategie-de-test.md).
- Règles métier et sécurité : test d'abord (rouge, vert, refactorisation).

## Données de test
Uniquement des données fictives : numéros inventés, noms inventés, aucun document d'identité réel. Voir [SECURITY.md](SECURITY.md).

## Licence
Aucune licence n'est définie pour l'instant : tous droits réservés. Contribuer ne transfère rien tant que l'équipe n'a pas tranché.
