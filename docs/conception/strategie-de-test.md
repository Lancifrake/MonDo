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

## Défauts connus, non corrigés
1. **Aucune authentification des requêtes** : l'identité du membre (`membreId`) vient du corps de la requête. N'importe qui peut se faire passer pour le bénéficiaire et confirmer une cotisation. À corriger avant toute démo publique : requêtes signées avec la clé du téléphone ou jeton de session après OTP.
2. **Aucune validation des entrées à l'exécution** : les types TypeScript ne protègent pas contre un JSON mal formé (ex. `nombreMembres` non entier). À corriger avec une validation de schéma.
3. **Pas d'OTP SMS** : l'inscription ne prouve pas la possession du numéro.
4. **Données en mémoire** : perdues au redémarrage, pas encore de PostgreSQL.
5. **Les tests d'intégration partagent une application** : l'ordre des tests peut influer. À isoler quand la base arrivera.

## Documentation de test (29119-3), version allégée
Ce document tient lieu de plan de test. Les cas de test sont les fichiers `*.test.ts`, nommés par comportement attendu. Les rapports sont la sortie de `pnpm qualite` et de l'intégration continue.
