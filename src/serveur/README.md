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
corepack pnpm build            # compile dans dist/
corepack pnpm start            # lance le serveur compilé (port 3000, ou PORT)
corepack pnpm essai-demarrage  # démarre dist/, vérifie /sante et l'arrêt propre
```

- `GET /sante` (sans signature) : 200 `{ "statut": "ok" }` si la base répond, 503 sinon. Pour l'hébergeur.
- Sans `DATABASE_URL`, `start` utilise la base embarquée en mémoire : pratique pour essayer, données perdues à l'arrêt.
- L'intégration continue compile le serveur et lance l'essai de démarrage après `pnpm qualite`.

## Structure

| Dossier                     | Rôle                                                           |
| --------------------------- | -------------------------------------------------------------- |
| `src/modules/comptes`       | inscription, clé publique, niveau d'identité                   |
| `src/modules/cercles`       | règlement signé, adhésions signées, ordre figé à la complétion |
| `src/modules/score`         | score = rejeu des événements                                   |
| `src/modules/cotisations`   | paiement déclaré, confirmé par le seul bénéficiaire            |
| `src/modules/planificateur` | rappels et constats de défaut rejouables, passage chaque heure |
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

**Défaut automatique** : le planificateur (`examinerEcheances`) constate le défaut d'une cotisation ni payée ni déclarée dès que sa fin de grâce est passée, une seule fois par tour (score −30, mise en demeure, assistant). Une cotisation déclarée mais pas confirmée par le bénéficiaire n'est jamais un défaut du payeur : elle relève d'un litige (pas encore codé). La mise en demeure est datée du constat et ne réclame que les cotisations échues à cette date, jamais les tours à venir.

**Passage régulier** : au démarrage du serveur (`main.ts`), le planificateur passe une première fois pour rattraper un arrêt, puis toutes les heures. Jamais deux passages en même temps ; un passage en échec est journalisé et le suivant a lieu quand même ; à l'arrêt, le passage en cours se termine avant la fermeture de la base. Les tâches étant rejouables, passer souvent ou sur plusieurs instances ne double ni un rappel ni un défaut.

- `MONDO_PLANIFICATEUR_MINUTES` : intervalle en minutes (60 par défaut), `0` pour désactiver ; une valeur invalide empêche le démarrage.
- Les tests ne démarrent pas la minuterie : ils appellent `examinerEcheances` avec leur propre date.

**Fin de cycle** (choix de David, 05/11) : bonus « cycle terminé » (+10) pour un membre quand la fin de grâce du dernier tour est passée, qu'il n'a eu aucun défaut dans ce cercle (même régularisé ensuite) et que le bénéficiaire a confirmé toutes ses cotisations. S'il manque une confirmation, le bonus arrive au passage qui suit. Une seule fois par membre et par cercle.

Non fait : litige sur un paiement déclaré non confirmé, statut « terminé » du cercle.

## Dossier de preuve

`GET /preuve/cercles/:cercleId/membres/:membreId/dossier`, réservé aux autres membres du cercle, seulement après un défaut constaté. Contient : identité du débiteur, règlement et engagement signés (vérifiables avec les clés publiques), preuves d'inscription au registre, relevé des cotisations, mises en demeure. L'export lui-même est inscrit au registre.

Non fait, en attente de décision : reconnaissance de dette (créancier et montant à trancher avec un juriste), clôture du dossier après régularisation (MonDo ne suit pas le paiement des pénalités), envoi réel de la mise en demeure (simulé), export PDF.

## Inscription

1. `POST /comptes/otp` avec le numéro : un code à 6 chiffres part par SMS (simulé : visible dans le journal du serveur).
2. `POST /comptes` avec numéro, nom, clé publique, preuve de détention de la clé et code SMS.
