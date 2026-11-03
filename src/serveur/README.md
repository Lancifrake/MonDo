# Serveur MonDo

Monolithe modulaire en TypeScript avec NestJS (décisions 02 et 03), données dans PostgreSQL, un schéma par module.

## Base de données

- `DATABASE_URL` définie : vrai serveur PostgreSQL (Supabase ou autre). Les migrations (`src/base/migrations.ts`) s'appliquent au démarrage.
- `DATABASE_URL` absente : PostgreSQL embarqué (PGlite) en mémoire, pour le développement. Données perdues à l'arrêt.
- Les tests utilisent une base PGlite neuve par fichier. Le test `src/base/postgres.integration.test.ts` rejoue le parcours sur un vrai serveur si `MONDO_TEST_POSTGRES_URL` pointe vers un serveur **de test** : il y crée puis supprime une base jetable.
- Une migration appliquée ne se modifie jamais : on en ajoute une nouvelle.

## Lancer

pnpm n'est pas forcément installé : `corepack enable` une fois, ou préfixer par `corepack`.

```bash
corepack pnpm install
corepack pnpm test
corepack pnpm verifier-types
```

## Structure

| Dossier                     | Rôle                                                           |
| --------------------------- | -------------------------------------------------------------- |
| `src/modules/comptes`       | inscription, clé publique, niveau d'identité                   |
| `src/modules/cercles`       | règlement signé, adhésions signées, ordre figé à la complétion |
| `src/modules/score`         | score = rejeu des événements                                   |
| `src/modules/cotisations`   | paiement déclaré, confirmé par le seul bénéficiaire            |
| `src/modules/planificateur` | constats de défaut rejouables                                  |
| `src/modules/preuve`        | dossier de preuve (à faire)                                    |
| `src/evenements`            | bus d'événements internes entre modules                        |
| `src/registre`              | arbre de hachage, inscription par lots (connecteur simulé)     |
| `src/signature`             | vérification ECDSA P-256, JSON canonique                       |
| `src/score`                 | règles pures : points, ordre de passage                        |
| `src/assistant`             | assistant multi-agents (décision 04)                           |

## Règles

Un module ne lit que ses propres données et passe par les services exportés ou par les événements des autres. Les connecteurs externes restent simulés.

## Dossier de preuve

`GET /preuve/cercles/:cercleId/membres/:membreId/dossier`, réservé aux autres membres du cercle, seulement après un défaut constaté. Contient : identité du débiteur, règlement et engagement signés (vérifiables avec les clés publiques), preuves d'inscription au registre, relevé des cotisations, mises en demeure. L'export lui-même est inscrit au registre.

Non fait, en attente de décision : reconnaissance de dette (créancier et montant à trancher avec un juriste), clôture du dossier après régularisation (MonDo ne suit pas le paiement des pénalités), envoi réel de la mise en demeure (simulé), export PDF.
