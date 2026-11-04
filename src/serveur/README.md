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

## Tours de cotisation

Générés d'un coup quand le cercle est complet (`src/modules/cotisations/calendrier.ts`), à partir du règlement signé et de l'ordre figé. On ne crée plus une cotisation à la main.

- **Date du premier tour** : champ `datePremierTour` du règlement, dans le futur à la création (choix de David, 05/11). Si le cercle se complète à cette date ou après, le départ est décalé d'autant de périodes qu'il faut.
- **Un tour par membre**, dans l'ordre de passage. Tours suivants : +7 jours en hebdomadaire, même jour chaque mois en mensuel (le 31 devient le dernier jour des mois plus courts, sans dériver).
- **Chaque membre doit le montant du règlement à chaque bénéficiaire sauf lui-même** : la cagnotte reçue vaut (nombre de membres − 1) × montant.
- **Fin de grâce** = date limite + délai de grâce du règlement, copiée sur chaque cotisation.
- `GET /cotisations?cercleId=…` : ce que le membre doit et ce qu'on lui doit dans ce cercle, rien sur les autres.

Non fait : constat automatique du défaut à la fin de grâce (prochaine étape), fin de cycle.

## Dossier de preuve

`GET /preuve/cercles/:cercleId/membres/:membreId/dossier`, réservé aux autres membres du cercle, seulement après un défaut constaté. Contient : identité du débiteur, règlement et engagement signés (vérifiables avec les clés publiques), preuves d'inscription au registre, relevé des cotisations, mises en demeure. L'export lui-même est inscrit au registre.

Non fait, en attente de décision : reconnaissance de dette (créancier et montant à trancher avec un juriste), clôture du dossier après régularisation (MonDo ne suit pas le paiement des pénalités), envoi réel de la mise en demeure (simulé), export PDF.

## Inscription

1. `POST /comptes/otp` avec le numéro : un code à 6 chiffres part par SMS (simulé : visible dans le journal du serveur).
2. `POST /comptes` avec numéro, nom, clé publique, preuve de détention de la clé et code SMS.
