# Stratégie de test et de qualité

Date : 03/11/2026. Statut : proposée. Référentiels : ISO/IEC 25010 (modèle de qualité), ISO/IEC/IEEE 29119 (processus et documentation de test), vocabulaire et techniques ISTQB. Ce document est une adaptation légère à un prototype d'un mois, pas une mise en conformité complète.

## Barrière de qualité
Une pull request n'est fusionnée que si `pnpm qualite` passe, en local et dans l'intégration continue (`.github/workflows/qualite.yml`) :
1. lint (ESLint, `typescript-eslint`, règles strictes) ;
2. types (TypeScript strict, `noUncheckedIndexedAccess`) ;
3. format (Prettier) ;
4. tests et couverture (Vitest, seuils : lignes 85 %, branches 75 %).

## Façon de travailler
- **Test d'abord pour les règles métier et la sécurité** : écrire le test qui échoue, le faire passer, puis refactoriser. Exemple du 03/11 : deux failles de l'arbre de hachage ont été montrées par des tests rouges avant d'être corrigées.
- **Refactorisation** seulement avec les tests au vert, dans un commit séparé.
- **Relecture** par un autre membre (CONTRIBUTING.md).

## Niveaux de test (ISTQB)
| Niveau | Ce qu'on teste | Outil | État |
|---|---|---|---|
| Composant | règles pures : score, ordre de passage, arbre de hachage, signature, agents | Vitest | fait |
| Intégration | modules NestJS reliés par les événements, API HTTP | Vitest + Nest testing | fait en partie |
| Système | parcours complets sur l'application mobile | Maestro ou Detox | à faire |
| Acceptation | scénario de démo : 10 membres, un défaut | script de démo | à faire |

## Techniques de conception (ISO/IEC/IEEE 29119-4)
- **Partitions d'équivalence** : niveau 1 et niveau 2, cercle privé et ouvert, signature valide, d'un autre téléphone, illisible.
- **Valeurs limites** : score 0 et 100, seuil 59 et 60, délai de grâce atteint ou dépassé, lot de 1 feuille, lots impairs.
- **Transitions d'état** : cotisation due, déclarée, confirmée ; cercle en attente, complet.
- **Tests de propriété** : déterminisme (100 lancements identiques), plancher et plafond du score.

## Caractéristiques de qualité ISO/IEC 25010 pour MonDo
| Caractéristique | Ce qui compte ici | Comment on le vérifie |
|---|---|---|
| Aptitude fonctionnelle | règles du score, de l'ordre, des confirmations | tests de composant et d'intégration, traçabilité règle vers test |
| Efficacité des performances | tour complet de l'assistant en moins de 2 s, lots du registre | mesures dans les tests (décision 04) |
| Compatibilité | téléphones Android d'entrée de gamme | tests sur appareil, à faire |
| Utilisabilité | français et anglais, réseau faible, mots simples | tests utilisateurs sur maquettes, à faire |
| Fiabilité | planificateur rejouable, panne SMS sans blocage | tests d'idempotence (fait), file d'attente (à faire) |
| Sécurité | signatures, clé privée jamais transmise, registre sans donnée personnelle, intégrité des preuves | tests négatifs (fait), revue de sécurité, SECURITY.md |
| Maintenabilité | modules indépendants (décision 02) | lint, test qui interdit les imports entre modules, couverture |
| Portabilité | changement d'hébergeur ou de réseau EVM | connecteurs derrière des interfaces |

## Corrigé le 03/11
- **Authentification** : chaque requête est signée par la clé du téléphone (en-têtes `x-mondo-membre`, `x-mondo-horodatage`, `x-mondo-signature`), valable 5 minutes et une seule fois. L'identité n'est plus jamais lue dans le corps. Seule l'inscription est publique, avec preuve de détention de la clé.
- **Validation des entrées** : schémas Zod stricts sur chaque corps de requête (champs inconnus refusés).

- **PostgreSQL** : un schéma par module, sans clé étrangère entre schémas ; contraintes d'unicité ; verrou de ligne contre la course pour la dernière place d'un cercle ; mises à jour conditionnelles contre les doubles confirmations ; anti-rejeu stocké en base (serveur sans état). Vérifié sur PGlite et sur un vrai PostgreSQL.

- **Code SMS (simulé)** : inscription conditionnée à un code à 6 chiffres, valable 5 minutes, 5 essais, usage unique, jamais stocké en clair, renvoi limité à un par minute ; connecteur SMS simulé refusé en production.

## Défauts connus, non corrigés
1. **Pas de limite d'envoi de codes par adresse IP** : quelqu'un peut demander des codes pour beaucoup de numéros (coût SMS). À ajouter avec le vrai fournisseur.
2. **Empreinte du code SMS sur 6 chiffres** : si la base fuitait, un code encore valide se retrouverait par essais ; durée de vie de 5 minutes seulement.
3. **Les tests d'un même fichier partagent une base** (une base neuve par fichier) : ils utilisent des identités distinctes pour rester indépendants.
4. **Confirmation et score ne sont pas dans une même transaction** : l'événement est publié après la mise à jour de la cotisation. Une panne entre les deux perdrait le point de score. À traiter par une table d'événements à publier (outbox) avant le pilote.
5. **Ordre de passage calculé juste après la transaction d'adhésion** : une panne à ce moment laisserait un cercle complet sans ordre, ce qui est détectable et recalculable.

## Documentation de test (29119-3), version allégée
Ce document tient lieu de plan de test. Les cas de test sont les fichiers `*.test.ts`, nommés par comportement attendu. Les rapports sont la sortie de `pnpm qualite` et de l'intégration continue.
