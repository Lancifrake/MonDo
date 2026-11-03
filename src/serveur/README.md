# Serveur MonDo

Monolithe modulaire en TypeScript avec NestJS (décisions 02 et 03). Le prototype garde tout en mémoire derrière des interfaces ; PostgreSQL vient ensuite.

## Lancer
pnpm n'est pas forcément installé : `corepack enable` une fois, ou préfixer par `corepack`.

```bash
corepack pnpm install
corepack pnpm test
corepack pnpm verifier-types
```

## Structure
| Dossier | Rôle |
|---|---|
| `src/modules/comptes` | inscription, clé publique, niveau d'identité |
| `src/modules/cercles` | règlement signé, adhésions signées, ordre figé à la complétion |
| `src/modules/score` | score = rejeu des événements |
| `src/modules/cotisations` | paiement déclaré, confirmé par le seul bénéficiaire |
| `src/modules/planificateur` | constats de défaut rejouables |
| `src/modules/preuve` | dossier de preuve (à faire) |
| `src/evenements` | bus d'événements internes entre modules |
| `src/registre` | arbre de hachage, inscription par lots (connecteur simulé) |
| `src/signature` | vérification ECDSA P-256, JSON canonique |
| `src/score` | règles pures : points, ordre de passage |
| `src/assistant` | assistant multi-agents (décision 04) |

## Règles
Un module ne lit que ses propres données et passe par les services exportés ou par les événements des autres. Les connecteurs externes restent simulés.
