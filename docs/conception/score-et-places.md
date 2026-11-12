# Score de fiabilité et règle des premières places

Date : 27/10/2026, mis à jour le 11/11/2026. Statut : **proposition de travail**, sauf ce qui est marqué « choix de David ». Un nouveau membre commence à **0**. Tous les autres nombres sont des valeurs de départ à régler par simulation (scénario du PDF : 10 membres, un défaut).

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

**Cercles privés** (choix de David, 11/11) : dans un cercle privé, les gains comptent moitié moins (+2 pour une cotisation à temps, +5 pour un cycle terminé). Les pertes restent entières (−1, −30, −15). Le score sert à juger des inconnus : des amis qui se cotisent entre eux ne doivent pas ouvrir trop vite les premières places d'un cercle ouvert.

**Départ en cours de cycle** (choix de David, 11/11) : libre tant que le membre n'a rien reçu de sa cagnotte, −15 ; impossible après. Règle détaillée dans `decision-05-choix-economiques-et-places.md`.

**Moment du bonus de fin de cycle** (décidé par David le 05/11) : quand la fin de grâce du dernier tour est passée, si le membre n'a eu aucun défaut dans ce cercle et que toutes ses cotisations ont été confirmées par leur bénéficiaire. Un paiement déclaré mais pas encore confirmé fait attendre le bonus jusqu'à la confirmation. Un défaut régularisé ensuite prive quand même du bonus.

Exemple pour un cercle hebdomadaire de 10 membres : après un cycle sans retard, 10 × 4 + 10 = 50. Après un deuxième cycle, 100 (plafonné).

### Conséquence du départ à 0
- Un nouveau et un membre tombé à 0 après un défaut ont le même score. Le score seul ne les distingue pas. **L'application affiche donc à côté du score le nombre de cycles terminés et le nombre de défauts.**
- Un retard de −1 n'a aucun effet visible pour un nouveau à 0 : la pénalité de retard repose alors sur la pénalité en argent du règlement, pas sur le score.
- L'accès aux premières places est lent (voir ci-dessous). C'est le prix d'un départ à 0, à mesurer par simulation.

## Les places : trois zones
1. **Début de cycle (premier tiers)** : réservé aux membres dont le score dépasse un seuil qui monte avec la taille de la cagnotte (proposition : 60 pour une petite cagnotte, 80 pour une grosse).
2. **Milieu** : à partir d'un score modeste (proposition : 30).
3. **Fin de cycle** : ouvert à tous, y compris aux nouveaux.

**Choix de la place (choix de David, 08/11, codé)** : le score ouvre les zones, le membre choisit. Chacun signe la place qu'il souhaite en rejoignant le cercle (l'organisateur avec le règlement), jamais plus tôt que ce que permet son score, toujours possible plus tard. L'attribution se fait quand le cercle est complet (`src/serveur/src/score/attribution-des-places.ts`) :
1. par priorité, score décroissant puis premier inscrit, chacun obtient sa place si elle est libre, sinon la place libre la plus proche parmi celles que permet son score, la plus tardive à égalité ;
2. ceux qui ne trouvent aucune place permise (cercle de nouveaux) prennent les places restantes, le mieux classé la plus tôt.
Pas de tirage au sort (le tirage par blockhash de Rota est manipulable), jamais d'enchères. Les cercles créés avant le 08/11, sans place souhaitée, gardent l'ordre par zones puis score décroissant.

## Ordre fixé en cercle privé
Choix de David, 11/11 : dans un cercle privé, l'organisateur peut écrire l'ordre de passage dans le règlement. Chaque membre signe le règlement en connaissant cet ordre ; le score n'intervient pas. Jamais en cercle ouvert, jamais de tirage au sort.

## Les frais des premières places
Choix de David, 11/11 (modèle A) : les places du début paient des frais sur la cagnotte, 8 % pour la place 1, dégressif jusqu'à 0 % à la première place du milieu. Moitié pour MonDo, moitié en remise pour les places de fin. Les montants sont écrits dans le règlement signé. Règle détaillée dans `decision-05-choix-economiques-et-places.md`. Un score trop bas ne s'achète jamais : les frais ne donnent pas accès à une place que le score n'ouvre pas.

## Échange de places
Choix de David, 11/11 : après complétion, deux membres peuvent échanger leurs places. Gratuit au prototype, signé par les deux, expiré au bout de 48 h sans seconde signature, jamais vers une place plus tôt que ce que permet le score de celui qui avance, suspendu si un des deux comptes est en récupération.

## Cas limites
- **Cercle composé uniquement de nouveaux** : les premiers inscrits obtiennent les places de fin qu'ils ont demandées, les suivants prennent les places restantes dans l'ordre d'inscription (choix de David, 08/11).
- **Faux compte** : un défaillant qui recrée un compte repart à 0, donc en fin de cycle. Mais avec seulement un numéro de téléphone, il peut revenir sans limite avec une nouvelle carte SIM. La vérification d'identité de niveau 2 (carte d'identité) est exigée pour les cercles d'inconnus et pour recevoir une cagnotte, ce qui rend le retour beaucoup plus difficile.
- **Groupe qui gonfle ses scores puis prend une grosse cagnotte** : le seuil qui monte avec la cagnotte limite le risque sans le supprimer. À tester en simulation.

## À faire
Les choix du 11/11 sont rassemblés dans `decision-05-choix-economiques-et-places.md`, avec les questions restées ouvertes.

- Écrire la simulation (10 membres, un défaut) dans `src/` et régler les points et seuils.
- Faire vérifier le risque de requalification des frais en intérêts (`docs/juridique/recours-legaux.md`, section 6).
