# Décision 05 : frais, places et règles encore à trancher

Date : 05/11/2026. Statut : **à trancher en équipe**. Rien dans ce document n'est validé, sauf ce qui est marqué « décidé ». Les recommandations sont les miennes : elles servent de point de départ à la discussion, pas de décision.

## Pourquoi ce document
Le serveur fait maintenant tourner tout le cycle de vie d'un cercle : création, ordre de passage par score, tours, rappels, défauts, litiges, bonus de fin de cycle et clôture. La suite du code dépend de choix économiques et de règles de places qui ne sont pas encore pris. Ce document les rassemble, avec les options, une recommandation et ce que chaque choix débloque.

## Déjà décidé par David (05/11), pour mémoire
- **Date du premier tour** écrite dans le règlement, décalée d'autant de périodes qu'il faut si le cercle se complète trop tard.
- **Bonus de fin de cycle** (+10) : fin de grâce du dernier tour passée, aucun défaut dans le cercle, toutes les cotisations du membre confirmées.
- **Litige** sur un paiement déclaré non confirmé : ouvert par le payeur après 48 h, par le bénéficiaire qui dit n'avoir rien reçu, ou automatiquement à la fin de grâce ; tranché par un administrateur ; un refus remet la cotisation due ; aucune pénalité pour le bénéficiaire au prototype.
- **Cercle terminé** à la fin de grâce du dernier tour, impayés ou non.
- **Score de départ à 0** (27/10).

## Résumé
| N° | Question | Recommandation | Qui décide | Débloque |
|---|---|---|---|---|
| 1 | Les premières places se paient-elles toujours, ou seulement pour un échange ? | A : elles se paient toujours | équipe, puis juriste | les frais dans le règlement et l'ordre |
| 2 | Comment partager les frais ? | à chiffrer, exemple en trois parts | équipe | le calcul des frais et du bonus des derniers |
| 3 | Comment MonDo encaisse-t-il ses frais sans toucher l'argent ? | le bénéficiaire paie MonDo au prototype | équipe | le suivi des frais dus |
| 4 | Faut-il un plafond de cagnotte pour les nouveaux membres ? | oui, selon le score | équipe | l'adhésion à un cercle |
| 5 | Un membre peut-il reculer librement ? | oui, jamais avancer au-delà de son score | équipe | l'échange de places |
| 6 | Quels modes d'ordre propose-t-on ? | score obligatoire en cercle ouvert, ordre fixé possible en cercle privé | équipe | le règlement et le calcul de l'ordre |
| 7 | Comment trancher deux demandes pour la même place ? | score, puis ordre d'inscription ; jamais d'enchères | équipe | l'échange de places |
| 8 | À qui revient la pénalité de retard ? | au bénéficiaire du tour | équipe, puis juriste | la mise en demeure et le relevé |
| 9 | Que se passe-t-il si un membre quitte le cercle en cours de cycle ? | à discuter, rien n'est cadré | équipe | le départ (−15) |
| 10 | Qui est le créancier de la reconnaissance de dette, et pour quel montant ? | à trancher avec un juriste | juriste | la reconnaissance de dette signée |

## 1. Modèle de frais
Exemple de référence : 10 membres à 50 000 FCFA, soit une cagnotte de 500 000 FCFA par tour. Celui qui reçoit au tour 1 a l'argent tout de suite, comme un prêt sans intérêt ; celui qui reçoit au tour 10 a épargné et fait confiance aux autres pendant neuf tours.

Nos documents se contredisent : le document de vision parle de frais de première place, alors que `score-et-places.md` ne prévoit des frais que lors d'un échange.

| | A. Les premières places se paient toujours | B. On paie seulement pour échanger |
|---|---|---|
| Exemple | place 1 : 6 %, place 2 : 5 %, place 3 : 4 %…, bonus pour les dernières places | personne ne paie, sauf pour passer devant un membre qui accepte de céder sa place |
| Revenu de MonDo | régulier, à chaque cycle | faible et imprévisible |
| Équité | celui qui a un besoin urgent paie, celui qui attend est récompensé | la place dépend seulement du score |
| Risque juridique | plus fort : ressemble à un intérêt de prêt | plus faible |

Dans les deux cas, **le score décide qui a le droit d'être devant** : on n'achète jamais une place que son score n'autorise pas.

Taux : David penche pour **6 % de la cagnotte** (référence MoneyFellows), soit 30 000 FCFA sur 500 000 ; le bénéficiaire reçoit alors 470 000 FCFA. Pas encore validé en équipe.

**Recommandation : A**, c'est le modèle qui a prouvé sa rentabilité et il récompense ceux qui attendent. À faire valider par un juriste : risque de requalification en intérêts ou en activité de crédit (`docs/juridique/recours-legaux.md`, section 6).

## 2. Partage des frais
- **Option A** : trois destinataires possibles. Exemple en tiers sur 30 000 FCFA : 10 000 pour MonDo, 10 000 pour les derniers du cycle (le « bonus des derniers »), 10 000 pour le fonds de garantie de la phase 2, qui rembourse les membres lésés si quelqu'un fuit.
- **Option B** : une part pour le membre qui cède sa place, une part pour MonDo.

Tant que le fonds de garantie n'existe pas (phase 2), il faut dire où va sa part au prototype : à MonDo, aux derniers, ou pas prélevée.

## 3. Encaissement sans détenir les fonds
Les cotisations vont directement de chaque membre au bénéficiaire, par Mobile Money. MonDo ne peut donc pas retenir les frais au passage.
- **Prototype et phase 1** : le bénéficiaire paie lui-même ses frais à MonDo après avoir reçu la cagnotte. S'il ne paie pas, c'est traité comme une cotisation non payée (défaut, score).
- **Phase 2** : le partenaire agréé, qui gère l'argent, retient les frais avant de verser la cagnotte et les répartit.

**Recommandation** : la première solution au prototype, à condition que les frais soient chiffrés dans le règlement signé (sinon ils ne sont pas opposables).

## 4. Plafond pour les nouveaux membres
Dans un cercle où tous les membres sont nouveaux (score 0), quelqu'un doit quand même recevoir au tour 1. Aujourd'hui, c'est le premier inscrit. Il peut prendre la cagnotte et partir. On ne supprime pas ce risque, on le limite :
1. **Plafond selon le score** : avec un score de 0, on ne rejoint que des cercles à petite cagnotte (exemple : 100 000 FCFA au plus), et le plafond monte cycle après cycle.
2. **Premier tour à l'organisateur** quand tout le monde est nouveau. Fragile s'il est lui aussi inconnu.
3. **Retenue de la phase 2** : le premier ne touche que 80 % de la cagnotte. Ne couvre pas tout.

**Recommandation : la règle 1**, la plus simple et la plus solide. Elle répond aussi à la fraude préparée sur la durée (trois petits cycles parfaits, puis fuite avec une grosse cagnotte) : on ne reçoit pas tôt une cagnotte bien plus grosse que celles qu'on a déjà remboursées. Montants à fixer.

## 5. Droit de reculer
Reculer ne met personne en danger : celui qui passe en dernier fait confiance aux autres et ne peut pas partir avec l'argent.

**Recommandation** : on peut toujours reculer librement, on n'avance jamais au-delà de ce que permet son score. Avec le modèle A, celui qui recule touche en plus le bonus des derniers.

## 6. Mode d'ordre
Le règlement a déjà un champ « cercle ouvert ou privé ». On peut y ajouter un mode d'ordre :
- **Par score** : obligatoire pour un cercle ouvert à des inconnus.
- **Fixé par l'organisateur** : seulement pour un cercle privé. L'ordre est écrit dans le règlement et chaque membre le signe en le connaissant. Le score reste visible, à titre d'information.
- **Tirage au sort** : courant dans les tontines, à condition qu'il soit vérifiable par tous. Le tirage de Rota par blockhash est écarté, parce que les validateurs peuvent l'influencer.

**Recommandation** : score obligatoire en cercle ouvert, ordre fixé possible en cercle privé. Tirage seulement si on trouve une méthode vérifiable simple.

## 7. Égalités et conflits de places
- **Ordre par score** : à score égal, le premier inscrit au cercle passe devant. **Déjà codé.**
- **Deux demandes pour avancer à la même place** : celui qui occupe la place choisit à qui il cède ; frais fixes, jamais d'enchères (elles feraient monter les prix, avantageraient les plus riches et ressembleraient davantage à un intérêt) ; une demande sans réponse expire au bout de 48 h.
- **Deux membres veulent reculer à la dernière place** (convoitée avec le modèle A) : le meilleur score choisit en premier, puis l'ordre d'inscription.
- **Cercle privé à ordre fixé** : le conflit se règle avant, puisque chacun signe l'ordre en le connaissant.

**Recommandation** : partout, le score départage, puis l'ordre d'inscription. Jamais d'enchères, jamais de décision cachée prise par MonDo.

## 8. Pénalité de retard
L'organisateur la fixe dans le règlement. Aujourd'hui, le code l'utilise seulement dans la mise en demeure : une pénalité par cotisation échue et non payée au moment du défaut. Un retard payé dans le délai de grâce coûte −1 au score, mais MonDo ne suit pas le paiement de la pénalité.

Questions :
- **À qui revient-elle ?** Recommandation : au bénéficiaire du tour, puisque c'est lui qui attend son argent.
- **Est-elle due dès un retard dans le délai de grâce, ou seulement en cas de défaut ?**
- **Faut-il un plafond ?** Un juge peut réduire une pénalité jugée excessive (`recours-legaux.md`, section 6).

## 9. Départ en cours de cycle
Le score prévoit −15 pour un départ avant la fin du cycle, mais rien n'est cadré.
- Un membre qui a **déjà reçu** la cagnotte ne peut pas partir sans payer ce qu'il doit : partir, c'est faire défaut sur les tours restants.
- Un membre qui **n'a pas encore reçu** : peut-il partir ? Que deviennent les cotisations qu'il a déjà versées aux bénéficiaires précédents, et sa place dans l'ordre ?
- Peut-on le **remplacer** par un nouveau membre, qui signe le même règlement ?

À discuter avant de coder quoi que ce soit.

## 10. Reconnaissance de dette
Volontairement absente du code. Il faut savoir avec un juriste si elle vise chaque membre lésé, le cercle collectivement, ou un autre montage, et quelle formule rend le montant certain et liquide au moment du défaut (`recours-legaux.md`, sections 2 et 5).

## Choix techniques encore ouverts
Ils ne touchent pas aux règles, mais bloquent un pilote réel :
- **Hébergeur** du serveur et de la base (gratuit ou crédits étudiants, décision 03). Le serveur se lance déjà (`pnpm build` puis `pnpm start`), avec une route de santé.
- **Fournisseur SMS** réel, derrière la file d'envoi déjà en place.
- **Déploiement du registre** sur Base Sepolia, prévu plus tard, avec David.

## Ordre proposé pour décider
1. Questions 1, 2 et 3 ensemble : elles forment le modèle économique.
2. Question 4 : elle protège les cercles de nouveaux, le risque le plus immédiat.
3. Questions 5, 6 et 7 : elles débloquent les échanges de place.
4. Questions 8 et 9.
5. Question 10, avec le juriste, avant tout pilote réel.
