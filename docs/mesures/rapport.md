# Rapport de mesures du simulateur MonDo

Généré par `corepack pnpm simulation` (src/serveur). Données synthétiques : aucun membre réel. Chaque scénario est rejoué avec MonDo et avec une tontine traditionnelle de référence, à graine fixe : relancer la commande redonne exactement les mêmes chiffres (sauf les durées).

## Résultats

| Scénario | Impayés MonDo | Impayés tradition | Pertes des honnêtes MonDo | Pertes des honnêtes tradition | Retards MonDo | Retards tradition | Relances à la main (tradition) |
|---|---|---|---|---|---|---|---|
| S1-tontine-saine | 0,0 % | 0,0 % | 0 FCFA | 0 FCFA | 3 | 7 | 7 |
| S2-retards | 0,0 % | 0,0 % | 0 FCFA | 0 FCFA | 21 | 37 | 37 |
| S3-defaut-apres-reception | 0,0 % | 4,8 % | 0 FCFA | 650 000 FCFA | 6 | 8 | 21 |
| S4-cercle-de-nouveaux | 3,0 % | 7,4 % | 400 000 FCFA | 1 000 000 FCFA | 11 | 12 | 32 |
| S5-mixte | 1,9 % | 3,0 % | 100 000 FCFA | 175 000 FCFA | 20 | 36 | 44 |
| S6-grande-tontine | 1,8 % | 2,4 % | 800 000 FCFA | 1 130 000 FCFA | 207 | 432 | 552 |
| S7-connus-sous-le-seuil | 2,6 % | 4,1 % | 350 000 FCFA | 550 000 FCFA | 4 | 7 | 18 |

- **S1-tontine-saine** : 10 bons payeurs déjà connus, 3 cycles, 50 000 FCFA par cotisation, graine 101.
- **S2-retards** : 8 bons payeurs et 2 retardataires, 3 cycles, 50 000 FCFA par cotisation, graine 202.
- **S3-defaut-apres-reception** : 9 membres connus (deux cycles derrière eux) et 1 nouveau qui arrête de payer dès qu'il a reçu sa cagnotte, 3 cycles, 50 000 FCFA par cotisation, graine 303.
- **S4-cercle-de-nouveaux** : 10 nouveaux, dont un défaillant inscrit le premier : la limite connue de MonDo, 3 cycles, 50 000 FCFA par cotisation, graine 404.
- **S5-mixte** : 6 bons payeurs, 2 retardataires, 1 solde insuffisant, 1 défaillant nouveau, 3 cycles, 25 000 FCFA par cotisation, graine 505.
- **S6-grande-tontine** : 50 membres : 40 bons payeurs, 6 retardataires, 2 soldes insuffisants, 2 défaillants nouveaux, 2 cycles, 10 000 FCFA par cotisation, graine 606.
- **S7-connus-sous-le-seuil** : 9 membres connus mais avec un seul cycle derrière eux (score 46, sous le seuil de 60 du début) et 1 nouveau défaillant : question ouverte, 3 cycles, 50 000 FCFA par cotisation, graine 707.

## Ce que montrent les chiffres

- Face à des membres bien établis (deux cycles derrière eux), un nouveau qui veut partir avec la cagnotte n'a rien à gagner avec MonDo : son score le place en dernier, il a tout payé avant de recevoir (S3 : aucune perte, contre 650 000 FCFA sans MonDo). Sans MonDo, l'ordre tiré au sort le met souvent en tête. Dans le scénario mixte (S5), les pertes qui restent viennent du membre au solde insuffisant, pas du défaillant, qui finit par tout payer faute de pouvoir passer devant (d'où son score de 70).
- Les rappels de l'assistant réduisent les retards ; l'organisateur n'a plus de relance à faire à la main (S2, S5).
- Après un défaut, le membre n'est plus jamais placé en tête (fermeture des premières places), ce qui limite le second coup.

## Points non résolus, à montrer tels quels

- **Cercle de nouveaux (S4)** : au premier cycle, personne n'a de score ; un défaillant peut encore recevoir une cagnotte avant d'avoir tout payé. MonDo perd moins que la tradition, mais pas zéro. Les parades étudiées (plafond de cagnotte, premier tour à l'organisateur, retenue) sont dans la décision 05, question 4.
- **Membres connus sous le seuil du début (S7)** : quand personne n'atteint le score des premières places (60), ces places restent vides, puis vont, selon la règle du 08/11, aux mieux classés de ceux qui n'ont rien trouvé ; un nouveau peut alors y tomber. Le cahier des charges demande au contraire « aucun nouveau membre dans les premières places ». À trancher : faire avancer les mieux classés de tout le cercle, ou baisser le seuil du début.
- **Fraudeur patient dans un grand cercle (S6)** : dans un cercle de 50, un seul cycle parfait rapporte 100 points (49 cotisations à temps, plafonné). Un défaillant qui joue honnêtement un premier cycle prend la place 1 au cycle suivant, puis s'arrête de payer : c'est l'essentiel des pertes de S6 avec MonDo. Parades étudiées dans la décision 05 (questions 4 et 11) : plafond de cagnotte selon les cagnottes déjà remboursées, points plafonnés par cycle ou dans le temps.

## Système multi-agents (grille d'évaluation)

Scénario de démonstration de l'assistant (10 membres, rappels, un retard puis un défaut), 10 lancements : 3 cycles, 58 messages entre agents, durée la plus longue 0,029 ms (cible : moins de 2 secondes), résultat identique à chaque lancement. Dans les scénarios ci-dessus, la décision la plus longue des agents sur un cycle complet a pris 1,660 ms.

## Hypothèses du modèle de comportement

Ce sont des choix pour le prototype, pas des mesures sur de vraies tontines. Les changer change les chiffres.

- Bon payeur : 97,0 % à temps, 3,0 % en retard.
- Retardataire : 50,0 % à temps, 50,0 % en retard.
- Solde insuffisant : 60,0 % à temps, 25,0 % en retard, 15,0 % jamais payé.
- Défaillant : paie jusqu'à sa cagnotte, puis plus rien.
- Avec MonDo, les rappels évitent 50,0 % des retards.
- Tontine traditionnelle : tirage au sort à chaque cycle ; une par retard ou défaut.
- Les membres déjà connus ont un cycle complet dans MonDo avant le scénario ; chacun demande la place 1 et l'attribution tranche.

## Figures

- `taux-impayes.svg` : part des cotisations jamais payées, par scénario.
- `pertes-membres-honnetes.svg` : argent versé par les membres honnêtes sans le recevoir en retour.
- `score-par-profil.svg` : score moyen par profil après le scénario mixte.
