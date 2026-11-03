# Score de fiabilité et règle des premières places

Date : 27/10/2026. Statut : **proposition de travail**. Seule règle validée par David : un nouveau membre commence à **0**. Tous les autres nombres sont des valeurs de départ à régler par simulation (scénario du PDF : 10 membres, un défaut).

## Le score
Entre 0 et 100, visible par tous les membres du cercle. On gagne des points en payant à l'heure, on en perd quand on ne paie pas. La formule de Rota (`complétions×100 + cotisations×10 − défauts×50…`) n'est pas reprise : elle n'a pas de plafond et un utilisateur ne la comprend pas.

| Événement | Points |
|---|---|
| Nouveau membre, point de départ | 0 |
| Cotisation payée avant la date limite | +4 |
| Cotisation payée en retard, dans le délai de grâce | −1 |
| Défaut constaté (délai de grâce dépassé) | −30, et plus de première place au cycle suivant |
| Cycle terminé sans défaut | +10 |
| Départ avant la fin du cycle | −15 |

Le score ne descend jamais sous 0 ni ne dépasse 100.

Exemple pour un cercle hebdomadaire de 10 membres : après un cycle sans retard, 10 × 4 + 10 = 50. Après un deuxième cycle, 100 (plafonné).

### Conséquence du départ à 0
- Un nouveau et un membre tombé à 0 après un défaut ont le même score. Le score seul ne les distingue pas. **L'application affiche donc à côté du score le nombre de cycles terminés et le nombre de défauts.**
- Un retard de −1 n'a aucun effet visible pour un nouveau à 0 : la pénalité de retard repose alors sur la pénalité en argent du règlement, pas sur le score.
- L'accès aux premières places est lent (voir ci-dessous). C'est le prix d'un départ à 0, à mesurer par simulation.

## Les places : trois zones
1. **Début de cycle (premier tiers)** : réservé aux membres dont le score dépasse un seuil qui monte avec la taille de la cagnotte (proposition : 60 pour une petite cagnotte, 80 pour une grosse).
2. **Milieu** : à partir d'un score modeste (proposition : 30).
3. **Fin de cycle** : ouvert à tous, y compris aux nouveaux.

Dans chaque zone, ordre par score décroissant. Égalité : ordre d'inscription au cercle. Pas de tirage au sort (le tirage par blockhash de Rota est manipulable).

## Les frais pour avancer
Un membre éligible à une zone peut payer pour passer devant un autre membre de cette même zone qui accepte de lui céder sa place. Celui qui cède reçoit une part des frais (le « bonus des derniers » du PDF). Un score trop bas ne s'achète jamais. Pourcentage et répartition des frais à décider (le PDF cite 3 % pour Christelle ; MoneyFellows environ 6 % d'après le PDF).

## Cas limites
- **Cercle composé uniquement de nouveaux** : la zone de début reste vide, ordre d'inscription au cercle.
- **Faux compte** : un défaillant qui recrée un compte repart à 0, donc en fin de cycle. Mais avec seulement un numéro de téléphone, il peut revenir sans limite avec une nouvelle carte SIM. La vérification d'identité de niveau 2 (carte d'identité) est exigée pour les cercles d'inconnus et pour recevoir une cagnotte, ce qui rend le retour beaucoup plus difficile.
- **Groupe qui gonfle ses scores puis prend une grosse cagnotte** : le seuil qui monte avec la cagnotte limite le risque sans le supprimer. À tester en simulation.

## À faire
- Écrire la simulation (10 membres, un défaut) dans `src/` et régler les points et seuils.
- Décider du pourcentage des frais et de leur répartition.
- Vérifier le risque de requalification des frais en intérêts (`docs/juridique/recours-legaux.md`, section 6).
