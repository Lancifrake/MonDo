# Décision 05 : frais, places et règles encore à trancher

Date : 05/11/2026, mis à jour le 11/11/2026. Statut : **tranché par David le 11/11, à confirmer en équipe**, sauf la question 10 (reconnaissance de dette), qui attend un juriste. La section « Tranché le 11/11 » fait foi ; les sections 1 à 11 gardent les options discutées, pour mémoire.

## Pourquoi ce document
Le serveur fait maintenant tourner tout le cycle de vie d'un cercle : création, ordre de passage par score, tours, rappels, défauts, litiges, bonus de fin de cycle et clôture. La suite du code dépend de choix économiques et de règles de places qui ne sont pas encore pris. Ce document les rassemble, avec les options, une recommandation et ce que chaque choix débloque.

## Déjà décidé par David (05/11), pour mémoire
- **Date du premier tour** écrite dans le règlement, décalée d'autant de périodes qu'il faut si le cercle se complète trop tard.
- **Bonus de fin de cycle** (+10) : fin de grâce du dernier tour passée, aucun défaut dans le cercle, toutes les cotisations du membre confirmées.
- **Litige** sur un paiement déclaré non confirmé : ouvert par le payeur après 48 h, par le bénéficiaire qui dit n'avoir rien reçu, ou automatiquement à la fin de grâce ; tranché par un administrateur ; un refus remet la cotisation due ; aucune pénalité pour le bénéficiaire au prototype.
- **Cercle terminé** à la fin de grâce du dernier tour, impayés ou non.
- **Période libre** : hebdomadaire, mensuelle, ou tous les N jours (1 à 60) au choix du cercle, ouvert comme privé ; délai de grâce plus court que la période.
- **Score de départ à 0** (27/10).
- **Choix de la place, « le score ouvre, le membre choisit »** (08/11, à confirmer en équipe). Un bon score ne veut pas dire qu'on veut recevoir tôt : beaucoup font une tontine pour épargner. Règle :
  1. le score fixe les zones auxquelles on a droit (zones et seuils de `score-et-places.md`) : sous le seuil du milieu, seulement la fin ; au-dessus, le milieu ou la fin ; au-dessus du seuil du début, n'importe quelle place ;
  2. dans ce périmètre, le membre choisit sa place en rejoignant le cercle, et ce choix fait partie de son engagement signé ;
  3. deux membres veulent la même place : le meilleur score passe, puis le premier inscrit ; jamais d'enchères ;
  4. on peut toujours choisir plus tard que ce que permet son score, jamais plus tôt (le score ne s'achète pas) ;
  5. place de tête sans candidat autorisé (cercle de nouveaux) : elle revient au mieux classé de ceux qui n'ont pas trouvé de place permise ;
  6. modalités choisies par David le 08/11 et codées : attribution à la complétion (chacun signe sa place souhaitée et la règle), en cas de conflit la place libre la plus proche permise, plutôt après ; chacun voit sa place définitive avant le premier tour.
  Les frais en tête et la remise en fin (question 1) équilibreraient naturellement les choix ; c'est aussi la pratique de MoneyFellows, où la place se choisit à l'adhésion et où les premières places se débloquent par l'évaluation du membre.

## Tranché par David le 11/11 (à confirmer en équipe)
| N° | Question | Décision |
|---|---|---|
| 1 | Modèle de frais | **A** : les places de la zone de début paient des frais sur la cagnotte, 8 % pour la place 1, dégressif jusqu'à 0 % à la première place du milieu ; le milieu ne paie rien ; les places de fin reçoivent une remise |
| 2 | Partage | moitié MonDo, moitié places de fin |
| 3 | Encaissement | MonDo ne touche jamais l'argent des membres : après réception de sa cagnotte, le bénéficiaire paie sa part à MonDo par Mobile Money, suivie comme une cotisation (due, déclarée, confirmée) |
| 4 | Plafond pour les nouveaux | **pas de plafond** de cagnotte |
| 5 | Reculer, échanger | échange de places après complétion : gratuit au prototype, signé par les deux, expire à 48 h, jamais plus tôt que ce que permet le score, suspendu si un des comptes est en récupération |
| 6 | Mode d'ordre | « le score ouvre, le membre choisit » partout ; en cercle privé, l'organisateur peut fixer l'ordre lui-même dans le règlement, chacun le signe en le connaissant ; pas de tirage au sort |
| 8 | Pénalité de retard | au bénéficiaire du tour, une fois par cotisation, due à la fin de grâce, au montant du règlement |
| 9 | Départ en cours de cycle | libre avant d'avoir reçu la cagnotte (score −15) ; impossible après (tout arrêt est un défaut) |
| 11 | Score gonflé | les cercles privés rapportent moitié moins de points ; les pertes (retard, défaut, départ) restent entières |

Autres décisions du 11/11, hors de ce document : vérification d'identité faite en interne (recto, verso, selfie, validation par un Administrateur), récupération de compte en 48 h avec contact de confiance et 72 h avec carte et selfie sans contact, contact de confiance exigé au niveau 2. Elles sont décrites dans `src/serveur/README.md` et dans `diagramme-de-classes.md`.

### Règle détaillée des frais (modèle A)
Notations : N membres, montant M par cotisation, cagnotte nominale C = (N − 1) × M (le bénéficiaire ne se paie pas lui-même), d = partie entière de N / 3. Les places 1 à d forment le début, les d dernières la fin, le reste le milieu (mêmes zones que pour le choix de la place).

1. **Taux par place.** La place p du début paie 8 % × (d + 1 − p) / d de la cagnotte nominale. À 10 membres (d = 3) : place 1, 8 % ; place 2, 5,33 % ; place 3, 2,67 % ; place 4 et suivantes, rien.
2. **Montants entiers, arrondis en faveur de celui qui paie.** Part de MonDo = partie entière de la moitié des frais. Remise versée à chaque place de fin = partie entière de (moitié des frais / d). Les frais réellement dus sont la somme de ces parts : l'arrondi ne les augmente jamais.
3. **Chiffrés dans le règlement signé.** Le règlement porte le barème en francs, place par place (frais, part de MonDo, remise par place de fin). Le serveur refuse un règlement dont le barème ne correspond pas au calcul. Chaque membre signe donc des montants, pas une formule. Les cercles créés avant cette règle, sans barème, n'ont pas de frais.
4. **Qui paie quoi.** Proposition appliquée, à confirmer : la remise est répartie à parts égales entre les places de fin, et chaque bénéficiaire de tête la verse directement à chacun des membres concernés. Le bénéficiaire de la place p doit donc d + 1 sommes : une à MonDo, une à chaque membre d'une place de fin.
5. **Quand.** Les sommes sont créées quand le cercle est complet. Elles sont exigibles à la date limite du tour du bénéficiaire (le jour de sa cagnotte) et à régler au plus tard à la date limite du tour suivant.
6. **Suivi.** Chaque somme suit les états d'une cotisation : due, déclarée par celui qui paie (référence Mobile Money), confirmée par celui qui reçoit. Un Administrateur confirme la part de MonDo, sans jamais être celui qui la doit.
7. **Ce que MonDo ne fait pas.** MonDo ne retient rien, ne prélève rien et ne détient rien : il suit des paiements faits hors de lui. Sa propre part arrive sur son compte Mobile Money marchand comme un paiement de service.

Choix prudents faits en codant, à valider :
- les frais s'appliquent à tous les cercles, privés comme ouverts, et aux cercles privés à ordre fixé ;
- les frais sont calculés sur la cagnotte nominale du règlement, même si un membre fait défaut ensuite (question ouverte ci-dessous) ;
- une somme non réglée n'entraîne au prototype ni défaut, ni perte de score, ni mise en demeure : elle reste visible comme due. Le traitement d'un impayé de frais reste à décider.

### Règle détaillée du départ en cours de cycle
Proposition appliquée, à confirmer.

1. **Qui peut partir.** Un membre d'un cercle complet et non terminé, tant qu'il n'a rien reçu de sa cagnotte : aucune cotisation de son tour n'est déclarée ni confirmée. Après, le départ est refusé : arrêter de payer est un défaut.
2. **Être à jour.** Le départ est refusé si le membre a une cotisation échue non confirmée (date limite passée), un paiement déclaré en attente de confirmation ou un litige ouvert. Sinon, partir servirait à éviter un défaut.
3. **Son tour est supprimé.** Les cotisations que les autres lui devaient sont annulées. Les dates des autres tours ne bougent pas : la période de son tour reste vide.
4. **Ses cotisations futures sont annulées.** Les bénéficiaires suivants reçoivent une cagnotte diminuée de sa part.
5. **Ce qu'il a déjà versé lui est remboursé** par ceux qui l'ont reçu : chaque bénéficiaire déjà servi lui doit le montant de la cotisation confirmée. Le remboursement est suivi comme une cotisation (due, déclarée, confirmée), à régler avant une période entière à compter du départ. Ainsi chaque membre restant cotise et reçoit N − 2 fois.
6. **Score.** −15 pour le membre qui part, entier même en cercle privé. Il ne reçoit pas le bonus de fin de cycle.
7. **Trace.** Le départ est inscrit au registre (empreinte) et les autres membres sont prévenus par SMS.
8. **Frais du modèle A.** Les sommes de frais non réglées qui le concernent (frais qu'il devait, remises qu'on lui devait) sont annulées ; une remise qu'il a déjà reçue est à rembourser à celui qui l'a versée, avec le même suivi. Les frais des autres membres ne sont pas recalculés.

Non couvert, donc non codé : quitter un cercle qui n'est pas encore complet, remplacer le membre parti par un nouveau, départ de l'organisateur avant complétion.

### Questions ouvertes après le 11/11
1. Si un membre fait défaut envers un bénéficiaire de tête, celui-ci doit-il ses frais sur la cagnotte nominale ou sur ce qu'il a réellement reçu ?
2. Que risque un bénéficiaire qui ne paie pas ses frais ou sa remise (défaut, score, mise en demeure) ?
3. Après un départ, les frais et remises des autres membres doivent-ils être recalculés sur la cagnotte réduite ?
4. Le membre parti peut-il être remplacé, et peut-on quitter un cercle avant qu'il soit complet ?
5. La durée de conservation de la carte d'identité (5 ans après le dernier cercle, provisoire) et le taux de 8 % sont à faire valider par un juriste, avec le risque de requalification des frais en intérêts.

## Résumé des questions d'origine (05/11)
| N° | Question | Recommandation | Qui décide | Débloque |
|---|---|---|---|---|
| 1 | Les premières places se paient-elles toujours, ou seulement pour un échange ? | A : elles se paient toujours | équipe, puis juriste | les frais dans le règlement et l'ordre |
| 2 | Comment partager les frais ? | à chiffrer, exemple en trois parts | équipe | le calcul des frais et du bonus des derniers |
| 3 | Comment MonDo encaisse-t-il ses frais sans toucher l'argent ? | le bénéficiaire paie MonDo au prototype | équipe | le suivi des frais dus |
| 4 | Faut-il un plafond de cagnotte pour les nouveaux membres ? | oui, selon le score | équipe | l'adhésion à un cercle |
| 5 | Un membre peut-il reculer librement ? | réglé par le choix de la place (08/11) | équipe | l'échange de places |
| 6 | Quels modes d'ordre propose-t-on ? | choix encadré par le score (08/11) ; reste : ordre fixé en cercle privé | équipe | le règlement et le calcul de l'ordre |
| 7 | Comment trancher deux demandes pour la même place ? | score, puis ordre d'inscription ; jamais d'enchères | équipe | l'échange de places |
| 8 | À qui revient la pénalité de retard ? | au bénéficiaire du tour | équipe, puis juriste | la mise en demeure et le relevé |
| 9 | Que se passe-t-il si un membre quitte le cercle en cours de cycle ? | à discuter, rien n'est cadré | équipe | le départ (−15) |
| 10 | Qui est le créancier de la reconnaissance de dette, et pour quel montant ? | à trancher avec un juriste | juriste | la reconnaissance de dette signée |
| 11 | Comment empêcher de gonfler son score avec des cercles rapides entre amis ? | plafond (question 4), puis à choisir | équipe | les points du score |

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
**Réglé par le choix de la place (08/11)** : chacun choisit sa place dans le périmètre de son score, donc peut toujours se placer plus tard. Reste à voir si l'on peut aussi changer de place une fois le cercle complet (échange signé à deux, flow 5).

Reculer ne met personne en danger : celui qui passe en dernier fait confiance aux autres et ne peut pas partir avec l'argent.

**Recommandation** : on peut toujours reculer librement, on n'avance jamais au-delà de ce que permet son score. Avec le modèle A, celui qui recule touche en plus le bonus des derniers.

## 6. Mode d'ordre
**En partie réglé (08/11)** : le mode par défaut devient le choix encadré par le score (voir « Déjà décidé »), en cercle ouvert comme privé. Reste à trancher : l'ordre fixé par l'organisateur en cercle privé, et le tirage au sort.

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

## 11. Score gonflé par des cercles rapides entre amis
Depuis le 05/11, chaque cercle choisit sa période : hebdomadaire, mensuelle, ou tous les N jours (de 1 à 60). C'est utile pour les tontines réelles (journalières sur les marchés, tous les 10 ou 14 jours), et le rythme ne change rien à la sécurité de l'argent.

Le risque porte sur le score. Une cotisation à temps rapporte +4, quels que soient le montant et le rythme. Cinq amis peuvent créer un cercle quotidien à 500 FCFA, monter à un bon score en deux semaines, puis prendre les premières places d'un gros cercle d'inconnus. Le risque existait déjà en hebdomadaire, mais un rythme quotidien le rend bien plus rapide.

Parades possibles, cumulables :
1. **Plafond de cagnotte selon le score** (question 4) : on ne reçoit pas tôt une grosse cagnotte sans en avoir remboursé de comparables. Limite les dégâts, quel que soit le rythme.
2. **Les cercles privés comptent moins pour le score**, ou pas du tout, puisque le score sert à juger des inconnus.
3. **Points plafonnés dans le temps** : le score ne monte que d'un nombre limité de points par semaine.
4. **Points pondérés par le montant** : une cotisation de 500 FCFA rapporte moins qu'une de 50 000 FCFA.

**Recommandation** : la parade 1 d'abord, qui sert de toute façon aux nouveaux membres. Puis une des parades 2 ou 3, à régler avec la simulation du score prévue dans `score-et-places.md`. La 4 rend le score plus difficile à comprendre pour un membre.

## Choix techniques encore ouverts
Ils ne touchent pas aux règles, mais bloquent un pilote réel :
- **Hébergeur** du serveur et de la base (gratuit ou crédits étudiants, décision 03). Le serveur se lance déjà (`pnpm build` puis `pnpm start`), avec une route de santé.
- **Fournisseur SMS** réel, derrière la file d'envoi déjà en place.
- **Déploiement du registre** sur Base Sepolia, prévu plus tard, avec David.

## Ordre proposé pour décider
1. Questions 1, 2 et 3 ensemble : elles forment le modèle économique.
2. Question 4 : elle protège les cercles de nouveaux, le risque le plus immédiat.
3. Questions 5, 6 et 7 : elles débloquent les échanges de place.
4. Questions 8, 9 et 11.
5. Question 10, avec le juriste, avant tout pilote réel.
