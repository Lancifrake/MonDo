---
title: "MonDo, document de vision (version 2)"
lang: fr
---

# MonDo - Partie 1 : Idéation

## 1. Nom du produit

**MonDo**

Le nom joue sur deux sens. En argot camerounais, le « do » désigne l'argent : *MonDo*, c'est « mon argent », celui qu'on confie à la tontine et qu'on est sûr de récupérer. À l'oreille, il évoque aussi « monde » : la tontine ouverte à tout le monde, y compris à des inconnus.

*Slogan : « MonDo, ta tontine sans palabres. »*

**Promesse en une phrase :** plus de cahier, plus de captures d'écran, plus de relances à la main : MonDo tient la tontine à ta place, et chaque membre est noté.

## 2. Contexte

La tontine est le premier instrument d'épargne et de crédit des ménages Camerounais : environ 1 500 milliards de FCFA y circulent chaque année, et 58 % des Camerounais disent préférer ce mode d'épargne à la banque ([NSIA, juin 2026](https://droitmediasfinance.com/index.php/actualites/droit-des-assurances/1293-cameroun-nsia-lance-la-premiere-assurance-dediee-aux-tontines-pour-securiser-lepargne-collective-informelle)). Elle remplace souvent un crédit bancaire coûteux : le taux moyen des crédits aux particuliers atteignait 10,21 % en 2022 selon la BEAC ([AFP via Le360](https://afrique.le360.ma/societe/cameroun-les-ancestrales-tontines-se-digitalisent_U4DBPRVMPRG5BLRMEMZGWTPYTM/)).

Pourtant, la tontine repose entièrement sur la confiance et n'offre aucune garantie si un membre fait défaut ou si la caisse est mal gérée. Quatre problèmes en découlent :

- **Le défaut après la cagnotte** : celui qui a « bouffé » la tontine en début de cycle n'a plus d'intérêt immédiat à cotiser, et les derniers de la liste portent tout le risque.
- **Le risque lié au cash** : le trésorier garde parfois des millions en liquide, le cahier peut brûler ou être falsifié, et un seul retard bloque tout un tour ([Kolonell](https://kolonell.com/fr/blog/application-tontine-digitale-epargne-groupe-2026)).
- **Le cercle fermé** : faute de pouvoir faire confiance à des inconnus, on ne cotise qu'entre proches, ce qui limite le nombre de membres et les montants accessibles.
- **L'absence de recours légaux** : n'étant pas reconnue comme une institution financière formelle, la tontine règle ses litiges par la pression sociale plutôt que par la justice. Celui qui n'a pas de réseau, ou qui est l'inconnu du groupe, n'a aucun levier.

Des applications camerounaises comme Djangui, Tontine.plus, i-djangui, Nkap app ou Faroty ont numérisé la gestion des tontines ([AFP via Le360](https://afrique.le360.ma/societe/cameroun-les-ancestrales-tontines-se-digitalisent_U4DBPRVMPRG5BLRMEMZGWTPYTM/)). Elles suivent les paiements sans les garantir : un fonctionnaire raconte avoir perdu plus d'un million de FCFA épargné pendant un an dans une tontine en ligne ([AFP via Briefly](https://briefly.co.za/business-economy/economy/182138-ancient-community-banking-enters-digital-age-cameroon/)).

À l'international, le modèle a fait ses preuves : en Égypte, MoneyFellows dépasse 8,5 millions d'utilisateurs avec une tontine digitale qui évalue la fiabilité de chaque membre ([TechCrunch](https://techcrunch.com/2025/05/04/moneyfellows-raises-13m-to-take-its-group-savings-model-outside-egypt)). Aucun acteur ne propose cette approche en Afrique centrale à notre connaissance, mais EAA, lancée au Cameroun en 2026, va dans une direction proche (scoring et détection de fraude).

**MonDo part de ce constat** : il ne suffit pas de digitaliser la tontine, il faut la rendre plus sûre et lui donner un cadre qui se défend, y compris entre personnes qui ne se connaissent pas.

## 3. Enjeux et objectifs

MonDo doit rendre la tontine plus sûre entre inconnus, sans exiger d'argent à l'avance, avec un prototype livré en moins d'un mois.

### Les enjeux

- **Créer de la confiance entre inconnus**, sans les liens personnels qui font fonctionner la tontine traditionnelle.
- **Sécuriser sans exclure** : protéger les membres sans exiger une caution que les personnes qui ont besoin d'argent n'ont justement pas.
- **Donner un cadre qui se défend** : chaque engagement est écrit, signé et conservé, de façon à pouvoir être opposé en cas de litige.
- **Rester simple** : la technologie (scoring, signature, registre) reste invisible ; l'utilisateur paie en Mobile Money et ne voit qu'une tontine qui fonctionne.
- **Respecter le cadre réglementaire CEMAC** : la détention de fonds du public est encadrée, d'où un modèle reposant à terme sur un partenaire agréé.
- **Livrer un prototype fonctionnel en moins d'un mois**, en s'appuyant sur une base open source existante.

### Objectifs stratégiques

- Proposer la première tontine digitale du Cameroun qui **réduit le risque de défaut** au lieu de simplement suivre les paiements.
- Ouvrir la tontine à des personnes qui ne se connaissent pas, pour augmenter la taille des groupes et les montants accessibles.
- Établir un modèle économique viable fondé sur les frais d'accès anticipé à la cagnotte, moins coûteux qu'un crédit bancaire.

### Objectifs techniques

- **Score de fiabilité** : évaluer chaque membre à partir de son historique de paiement. Un nouveau membre commence à 0.
- **Attribution des places par le score** : réserver les premières places aux profils les plus fiables ; un nouveau membre commence en fin de cycle.
- **Signature électronique et dossier de preuve** : chaque membre signe le règlement et sa reconnaissance de dette avec une clé propre à son téléphone ; MonDo conserve les pièces et peut en exporter un dossier.
- **Registre de règles et de preuves sur blockchain**, sans aucun fonds et sans aucune manipulation crypto côté utilisateur : seules des empreintes des événements (cercle créé, cotisation confirmée, défaut constaté, score mis à jour) y sont inscrites.
- **Paiement par Mobile Money** (Orange Money, MTN MoMo), simulé dans le prototype, avec confirmation de réception par le bénéficiaire.
- **Retenue sur la cagnotte et fonds de garantie** : prévus en phase 2, avec un partenaire agréé (hors prototype).

### Objectifs organisationnels

- S'inspirer d'une base open source ([Rota](https://github.com/CodeWithShamim/Rota)) pour sa logique de réputation et ses tests, et écrire nous-mêmes l'ordre de passage par score, que Rota ne propose pas.
- Répartir le travail en lots parallèles : registre de règles, IA de scoring, application, document de vision et soutenance.
- Livrer un prototype démontrable avec un scénario complet : création d'une tontine, attribution des places, signature des engagements, défaut simulé, pénalité de score.

# MonDo - Partie 2 : Analyse

## 1. Groupes d'utilisateurs ciblés

MonDo s'adresse à cinq profils : la commerçante qui cotise pour financer son activité, le jeune salarié qui veut rejoindre des tontines plus grosses, l'organisatrice qui gère un groupe, le membre de la diaspora qui cotise à distance, et l'entrepreneure qui engage plusieurs millions.

### Persona 1 : Ma'a E, commerçante au marché Mokolo

- **Profil** : 45 ans, femme, vendeuse de pagnes à Yaoundé, mariée, 3 enfants. Membre de deux tontines de marché ; écoute la radio, très active sur WhatsApp.
- **Objectifs** : réunir 1 million de FCFA pour acheter son stock avant les fêtes ; payer la scolarité des enfants en septembre.
- **Frustrations** : la trésorière d'une ancienne tontine est partie avec la caisse ; deux membres ne paient plus depuis qu'ils ont « bouffé » ; elle perd une demi-journée de vente à chaque réunion. *« Je cotise depuis 8 mois et je ne sais même pas si on me paiera quand ce sera mon tour. »*
- **Environnement** : smartphone Android d'entrée de gamme, Orange Money, connexion 4G irrégulière, peu à l'aise avec les applications complexes.
- **Comment elle compense aujourd'hui** : elle ne cotise qu'avec des femmes de son marché qu'elle connaît depuis longtemps, garde un cahier personnel et relance elle-même par appel.

### Persona 2 : Junior, jeune salarié à Douala

- **Profil** : 27 ans, homme, technicien dans une entreprise de logistique, célibataire, salaire de 250 000 FCFA. Passionné de football, utilise TikTok et WhatsApp au quotidien.
- **Objectifs** : réunir 2 millions de FCFA pour acheter une moto et la mettre en location ; se constituer une épargne régulière.
- **Frustrations** : son cercle de proches ne cotise que 10 000 FCFA par mois, trop peu pour son projet ; il n'ose pas rejoindre des inconnus ; la banque lui refuse un crédit faute d'ancienneté. *« Je paie toujours à l'heure, mais personne ne le sait. »*
- **Environnement** : smartphone Android récent, MTN MoMo et Orange Money, moyenne connexion 4G en ville, à l'aise avec les applis.
- **Comment il compense aujourd'hui** : il épargne seul sur son compte Mobile Money et pioche dedans à chaque imprévu ; il emprunte parfois à sa famille.

### Persona 3 : Madame Ngono, organisatrice d'une tontine de collègues

- **Profil** : 38 ans, femme, comptable dans une administration à Yaoundé. Présidente d'une tontine de 20 collègues à 50 000 FCFA par mois.
- **Objectifs** : faire tourner la tontine sans conflits et garder la confiance du groupe.
- **Frustrations** : elle passe ses soirées à relancer les retardataires ; on la soupçonne de favoriser ses proches dans l'ordre de passage ; elle avance parfois l'argent de sa poche pour couvrir un retard. *« Je suis devenue la police de la tontine. »*
- **Environnement** : smartphone et ordinateur au bureau, Orange Money et compte bancaire, connexion stable.
- **Comment elle compense aujourd'hui** : un fichier Excel, un groupe WhatsApp, des captures d'écran des transferts comme preuves, et des pénalités de retard difficiles à faire appliquer.

### Persona 4 : Serge, membre de la diaspora à Lyon

- **Profil** : 34 ans, homme, infirmier en France, originaire de Bafoussam. Membre de la tontine de sa famille au pays.
- **Objectifs** : construire une maison au Cameroun ; garder un lien avec sa communauté.
- **Frustrations** : il ne sait jamais si sa cotisation a bien été reçue ; les frais de transfert s'accumulent ; il soupçonne des arrangements dans l'ordre de passage. *« Je paie de loin, mais je ne vois rien. »*
- **Environnement** : iPhone, carte bancaire et applications de transfert international, très bonne connexion, décalage horaire.
- **Comment il compense aujourd'hui** : il envoie l'argent à un cousin qui cotise pour lui et lui fait un compte rendu par message vocal.

### Persona 5 : Christelle, entrepreneure à Douala

- **Profil** : 42 ans, femme, propriétaire de deux boulangeries à Douala, mariée, 2 enfants. Membre d'une tontine de 20 commerçants et chefs d'entreprise à 1 000 000 FCFA par mois : la cagnotte atteint 20 millions de FCFA par tour. Très active dans les réseaux d'affaires de la ville.
- **Objectifs** : financer l'ouverture d'une troisième boulangerie (environ 20 millions de FCFA) ; à terme, acheter un terrain pour un atelier de production.
- **Frustrations** : avec ces montants, un seul défaut coûte plusieurs millions ; plusieurs membres ont été introduits par d'autres et elle les connaît mal ; l'ordre de passage se négocie en réunion et crée des tensions ; le trésorier transporte des liasses de billets, avec le risque de vol que cela implique. *« À 20 millions par tour, je ne peux plus me contenter d'une promesse. »*
- **Environnement** : smartphone haut de gamme et ordinateur, compte bancaire professionnel, Orange Money et MTN MoMo ; bonne connexion ; habituée aux applications bancaires.
- **Comment elle compense aujourd'hui** : un règlement signé sur papier, un trésorier de confiance, des réunions mensuelles où l'argent circule en liquide, et des virements bancaires pour les plus gros montants.

Ce profil porte l'essentiel du chiffre d'affaires : sur une cagnotte de 20 millions de FCFA, des frais de première place de 3 % rapportent 600 000 FCFA. Il est aussi le plus exigeant en garanties, ce qui justifie la retenue et le fonds de garantie de la phase 2 et, dès le prototype, un seuil de score plus élevé pour accéder tôt à une grosse cagnotte.

## 2. Bénéfices de la Smart Realization

Le succès de MonDo se mesure à six indicateurs SMART, évalués sur un pilote de 10 tontines (environ 150 membres) pendant 6 mois après le lancement. Les cibles sont des hypothèses de départ, à ajuster après le pilote.

| Bénéfice attendu | Indicateur (Spécifique, Mesurable) | Cible (Atteignable) | Pourquoi (Réaliste) | Échéance (Temporel) |
|---|---|---|---|---|
| Moins de défauts de paiement | Part des cotisations non payées après la date limite et le délai de grâce du cercle | Moins de 3 % | Le score place les profils à risque en fin de cycle | 6 mois après le lancement du pilote |
| Plus de ponctualité | Part des cotisations payées à temps | Plus de 90 % | Rappels automatiques et score visible par tous | 3 mois après le lancement |
| Tontines entre inconnus | Part des membres ayant rejoint un groupe où ils ne connaissaient personne | Au moins 30 % | Le score remplace la connaissance personnelle | 6 mois après le lancement |
| Moins de charge pour l'organisateur | Temps passé à relancer et vérifier | Divisé par 2 (mesuré par questionnaire avant/après) | Relances et suivi automatisés | 3 mois après le lancement |
| Confiance des utilisateurs | Note de satisfaction et intention de rejoindre une nouvelle tontine | Note ≥ 4/5 et 85 % prêts à recommencer | Historique certifié et règles verrouillées | Fin du premier cycle complet |
| Engagements opposables | Part des membres ayant signé le règlement et leur reconnaissance de dette avant leur premier paiement | 100 % | Aucun accès à un cercle sans signature | Dès le lancement du pilote |

Le délai de grâce n'est pas fixé à 7 jours pour tous : il dépend de la fréquence du cercle (proposition : environ un quart de la période, plafonné à 7 jours) et figure dans le règlement signé. Valeurs à tester pendant le pilote.

Pour le prototype livré en fin de projet, un indicateur de démonstration suffit : sur un scénario simulé de 10 membres avec un défaut, l'application détecte le défaut, pénalise le score, et le profil défaillant est exclu des premières places du cycle suivant, sans intervention humaine.

## 3. Analyse de la concurrence

Le produit existe sous forme de gestion de tontines, mais à notre connaissance aucun acteur camerounais ne réduit le risque de défaut d'un membre par un score qui décide de l'ordre de passage ; seul MoneyFellows, absent d'Afrique centrale, le fait par le scoring, et EAA semble s'en approcher. Les informations sur les concurrents viennent de leurs pages publiques et d'articles de presse ; elles restent à vérifier avant tout usage public.

| Solution | Pays | Ce qu'elle fait | Prix / modèle | Limite principale |
|---|---|---|---|---|
| [Djangui](https://www.businessincameroon.com/ict/1305-6220-a-cameroonian-engineer-invents-djangui-an-online-application-to-manage-tontines) | Cameroun (2016) | Cotisation par PayPal, Orange Money, MoMo ; messagerie ; tirages ; prêts sur la caisse ; 50 000 utilisateurs revendiqués | Non public | Suit les paiements sans les garantir |
| [FreemoPay](https://mwm.ai/apps/freemopay/6746784756) | Cameroun (2021) | Épargne collective, tontines, cotisations, collectes | Non public | Pas de mécanisme contre le défaut |
| Tontine.plus, i-djangui, Nkap app, yaNkap | Cameroun | Gestion et suivi des cotisations, rappels | Non public | Digitalisent la gestion, pas la confiance |
| [EAA](https://macaubusiness.com/eaa-entraide-amicale-dafrique-introduces-ai-automated-tontine-platform-for-digital-community-savings/) | Cameroun (2026) | Tontine automatisée, scoring comportemental GPT-4o, détection de fraude ; 271 membres actifs | Frais par transfert, 50 % redistribués aux membres actifs | Mobile Money seulement au Ghana ; IA tournée vers la fraude, pas vers l'ordre de passage |
| [Tontinéo](https://mwm.ai/apps/tontineo/6751351607) | Afrique francophone | Gestion de tontines, pénalités de retard | Offre découverte (1 tontine, 10 membres), puis abonnement mensuel ou annuel | Outil de gestion sans garantie |
| [MoneyFellows](https://techcrunch.com/2025/05/04/moneyfellows-raises-13m-to-take-its-group-savings-model-outside-egypt) | Égypte | Tontine digitale avec scoring ; 8,5 millions d'utilisateurs, rentable | Environ 6 % pour les premières places ([The Paypers](https://thepaypers.com/fintech/news/money-fellows-secures-usd-31-mln-in-series-b-funding-round)) | Absent d'Afrique centrale |
| [StepLadder](https://www.islamicfinanceguru.com/articles/a-detailed-review-of-stepladder-is-it-halal) | Royaume-Uni | Cercles d'épargne pour l'apport immobilier | 2 à 5 % de l'objectif d'épargne | Marché britannique uniquement |
| [NSIA Tontines](https://droitmediasfinance.com/index.php/actualites/droit-des-assurances/1293-cameroun-nsia-lance-la-premiere-assurance-dediee-aux-tontines-pour-securiser-lepargne-collective-informelle) | Cameroun (2026) | Assurance : rembourse la tontine en cas de décès ou d'invalidité d'un membre | Dès 2 820 FCFA par membre et par an | Ne couvre pas un membre qui arrête de payer |
| [Rota](https://github.com/CodeWithShamim/Rota) (open source) | Bangladesh | Tontine sur smart contracts : caution, prélèvement auto, réputation, enchère de places | Gratuit, licence MIT | Exige crypto (USDC) et wallet, caution à l'entrée ; non audité, testnet ; pas d'ordre par score |

**Problèmes rencontrés par les utilisateurs actuels** : la confiance reste nécessaire, car les applications suivent les paiements sans pouvoir les garantir. Un fonctionnaire raconte ainsi avoir perdu plus d'un million de FCFA dans une tontine en ligne ([AFP via Briefly](https://briefly.co.za/business-economy/economy/182138-ancient-community-banking-enters-digital-age-cameroon/)).

**Positionnement de MonDo** : plus de cahier, plus de captures d'écran, plus de relances à la main. MonDo tient la tontine à la place de l'organisateur, chaque membre est noté, l'ordre de passage est calculé selon une règle écrite et connue de tous, et chacun s'engage par écrit avant d'entrer. Tout se paie en Mobile Money. La technologie (registre, signature) reste en arrière-plan. De Rota, MonDo reprend la logique de réputation et les tests, pas le circuit de fonds.

## 4. Périmètre

Le prototype couvre le cycle complet d'une tontine sans que MonDo touche l'argent : les membres se paient directement par Mobile Money, MonDo organise, vérifie, note et conserve les preuves.

### Exigences fonctionnelles (user stories)

Priorité **MVP** = livré dans le prototype ; **V2** = après le prototype.

| Activité | User story | Priorité |
|---|---|---|
| S'inscrire | En tant qu'utilisateur, je veux créer un compte avec mon numéro de téléphone pour accéder à MonDo sans adresse e-mail. | MVP |
| S'inscrire | En tant qu'utilisateur, je veux choisir un code secret ; mon téléphone crée en arrière-plan la clé qui me permet de signer. | MVP |
| S'inscrire | En tant qu'utilisateur qui change ou perd son téléphone, je veux récupérer mon compte sans que quelqu'un d'autre puisse le faire à ma place (code SMS, code secret, délai d'attente, blocage temporaire du numéro de réception). | MVP |
| S'inscrire | En tant qu'utilisateur, je veux m'inscrire avec mon numéro et mon nom complet (niveau 1) pour parcourir le catalogue et rejoindre un cercle privé de personnes que je connais, pour de petits montants. | MVP |
| S'inscrire | En tant qu'utilisateur, je veux vérifier mon identité (carte d'identité et selfie, niveau 2) pour signer le règlement d'un cercle ouvert à des inconnus, recevoir une cagnotte ou dépasser un montant fixé. La vérification est simulée dans le prototype. | MVP |
| S'inscrire | En tant qu'utilisateur, je veux que mon identité soit vérifiée par un prestataire spécialisé, pour que mes engagements soient opposables. | V2 |
| Créer une tontine | En tant qu'organisateur, je veux définir le montant, la fréquence, le nombre de membres, les pénalités et le délai de grâce pour lancer une tontine. | MVP |
| Créer une tontine | En tant qu'organisateur, je veux inviter des membres par lien ou numéro pour remplir mon groupe. | MVP |
| Rejoindre | En tant que membre, je veux rejoindre une tontine ouverte à des inconnus selon mon score pour cotiser au-delà de mon cercle. | MVP |
| Rejoindre | En tant que membre fiable, je veux recommander un proche pour qu'il accède plus vite aux premières places, sans que cela m'engage financièrement à sa place. | MVP |
| Rejoindre | En tant que membre, je veux parcourir un catalogue de cercles filtrés par montant, durée et date de cagnotte pour trouver celui qui correspond à mon besoin. | MVP |
| Rejoindre | En tant que membre, je veux signer électroniquement le règlement et une reconnaissance de dette avant de rejoindre un cercle, pour que chacun soit engagé par écrit. | MVP |
| Rejoindre | En tant que membre, je veux participer à plusieurs cercles en même temps et associer à chacun un objectif personnel, visible par moi seul (scolarité, stock, terrain), pour recevoir chaque cagnotte au bon moment. | MVP |
| Ordre de passage | En tant que membre, je veux voir l'ordre de passage calculé selon les scores pour être sûr que personne n'est favorisé. | MVP |
| Ordre de passage | En tant que membre éligible à une zone de passage, je veux payer des frais pour passer devant un autre membre de cette même zone quand j'ai un besoin urgent. | MVP |
| Ordre de passage | En tant que membre, je veux recevoir une part des frais si j'accepte de céder ma place en avançant d'autres, pour être rémunéré de mon attente. | MVP |
| Ordre de passage | En tant que membre d'une grosse tontine, je veux que la date de ma cagnotte reste confidentielle, visible seulement dans le registre certifié, pour des raisons de sécurité. | V2 |
| Cotiser | En tant que membre, je veux savoir à qui envoyer ma part et la payer par Orange Money ou MoMo. | MVP |
| Cotiser | En tant que bénéficiaire, je veux confirmer chaque paiement reçu pour que la cotisation soit enregistrée. | MVP |
| Cotiser | En tant que membre, je veux recevoir des rappels avant la date limite pour ne pas être en retard. | MVP |
| Suivre | En tant que membre, je veux voir qui a payé et qui ne l'a pas fait pour suivre le tour en temps réel. | MVP |
| Score | En tant que membre, je veux consulter mon score (qui commence à 0), le nombre de cycles terminés et mes défauts, et comprendre comment débloquer de meilleures places. | MVP |
| Score | En tant que membre, je veux partager mon historique certifié pour prouver ma fiabilité à une autre tontine. | V2 |
| Défaut | En tant que membre, je veux que le défaut d'un membre soit constaté automatiquement à l'issue du délai de grâce et pénalise son score, sans dispute. | MVP |
| Recours | En tant que membre lésé, je veux exporter un dossier de preuve (identité vérifiée du débiteur, règlement signé, reconnaissance de dette, relevé des cotisations, mise en demeure datée) pour agir si je le décide. | MVP |
| Garantie | En tant que membre, je veux qu'une retenue et un fonds de garantie me remboursent si quelqu'un fait défaut. | V2 |
| Diaspora | En tant que membre à l'étranger, je veux cotiser par carte bancaire pour participer à distance. | V2 |

### Exigences non fonctionnelles

| Catégorie | Exigence |
|---|---|
| Sécurité | Connexion par code OTP envoyé par SMS ; engagements signés avec une clé propre à l'utilisateur, protégée par un code secret ; données chiffrées en transit (HTTPS) et au repos ; aucune donnée de paiement stockée par MonDo ; empreintes des événements (cotisations, défauts, scores) ancrées dans un registre non modifiable, sans donnée personnelle sur la chaîne ; pièces d'identité chiffrées, limitées au strict nécessaire, jamais inscrites sur la chaîne, avec une durée de conservation définie. |
| Conformité | MonDo ne détient jamais de fonds ; aucune cryptomonnaie manipulée par les utilisateurs ; protection des données personnelles ; conservation des documents signés et accès pour les membres qui le demandent. Le parrainage ne crée pas de caution. |
| Capacité | Prototype : 50 tontines et 1 000 utilisateurs simultanés ; tontines de 5 à 50 membres. |
| Compatibilité | Application web installable (PWA) adaptée au mobile : elle s'ouvre depuis le navigateur et s'installe sur l'écran d'accueil, sur Android comme sur iOS, sans passer par les stores ; version complète sur ordinateur pour les organisateurs ; Orange Money et MTN MoMo (simulés dans le prototype). |
| Fiabilité et disponibilité | Disponibilité visée de 99 % ; aucune cotisation perdue : file d'attente et nouvel essai en cas de coupure réseau. |
| Évolutivité | Architecture modulaire : ajout d'un nouveau moyen de paiement ou d'un partenaire agréé sans refonte. |
| Maintenabilité | Code documenté sur GitHub, tests automatisés sur le registre de règles et sur le calcul du score. |
| Utilisabilité | Parcours de cotisation en 3 écrans maximum ; interface en français et en anglais ; consultation possible hors connexion ; adaptée aux téléphones d'entrée de gamme et aux connexions 3G. |

## 5. Ressources nécessaires

Le prototype mobilise une équipe de 5 personnes sur 4 semaines. La répartition suit la charge réelle de chaque lot plutôt qu'un découpage par technologie : la blockchain et l'IA pèsent moins, car le registre ne porte que des règles et des empreintes, et le score reste un calcul à règles pondérées dans le prototype.

### Ressources matérielles

- **Logiciel et services** : logique de réputation et tests inspirés de [Rota](https://github.com/CodeWithShamim/Rota) (licence MIT), GitHub, réseau blockchain de test, hébergement et base de données en offre gratuite, simulateur Mobile Money. Coût du prototype quasi nul, hors forfaits internet.

## 6. Perspectives à long terme

Après le prototype, MonDo évolue en trois phases : un pilote réel sans détenir l'argent, puis une garantie financière avec un partenaire agréé, puis des services financiers construits sur le score.

### Phase 1 : pilote réel (sans détention de fonds)

- Lancer 10 tontines pilotes à Yaoundé et Douala et mesurer les indicateurs SMART.
- Connecter les API réelles d'Orange Money et MTN MoMo, pour confirmer les cotisations automatiquement.
- Brancher un prestataire de vérification d'identité (couverture du Cameroun, coût et conservation des pièces à vérifier).
- **Porte avant tout pilote réel : faire valider par un juriste camerounais** la valeur de la signature électronique, la reconnaissance de dette, le dossier de preuve, la qualification des frais de première place et le fait que MonDo reste un logiciel de gestion tant qu'il ne détient aucun fonds.

### Phase 2 : la garantie financière, avec un partenaire agréé

C'est la phase où MonDo garantit l'argent, et plus seulement l'engagement.

- **Un partenaire agréé détient les fonds** : banque, établissement de microfinance ou établissement de paiement, conformément au règlement CEMAC n° 04/18 sur les services de paiement. L'argent reste en FCFA sur un compte dédié ; MonDo ne le touche jamais.
- **Les règles donnent les ordres, le partenaire les exécute** : les règles restent dans le registre, les mouvements d'argent se font chez le partenaire.
- **La retenue sur la cagnotte** : les premiers bénéficiaires reçoivent par exemple 80 % de la cagnotte ; les 20 % restants sont bloqués et restitués en fin de cycle s'ils ont tout payé. Aucune caution à avancer.
- **Le fonds de garantie** : alimenté par une partie des frais de première place, il rembourse automatiquement les membres lésés en cas de défaut.
- **Le bonus des derniers** : une partie des frais rémunère ceux qui acceptent de passer en fin de cycle.
- **Le prélèvement automatique** des cotisations, avec l'accord du membre.
- Prérequis : convention avec le partenaire, vérification d'identité (KYC), avis juridique sur le statut de MonDo (distributeur du partenaire ou agrément propre), et nouvel examen de la retenue et du fonds de garantie au regard des règles sur les sûretés (la signature électronique d'une sûreté par un particulier est exclue par la loi 2010/021, art. 13).

### Phase 3 : services financiers construits sur le score

- **Passeport de crédit** : avec l'accord du membre, partager son historique certifié avec des banques et microfinances, pour accéder à un crédit sans ancienneté bancaire.
- **Assurance intégrée** : proposer une couverture décès-invalidité de partenaires comme NSIA Tontines.
- **Achat avec la cagnotte** : partenariats avec des marchands (motos, électroménager, matériaux) pour acheter directement avec sa cagnotte, à prix négocié.
- **Diaspora** : cotisation par carte bancaire depuis l'étranger.
- **Expansion** : autres pays de la CEMAC, puis Afrique de l'Ouest, où la tontine porte d'autres noms (esusu, susu, natt).
- **IA conversationnelle** : un assistant qui explique le score, conseille la tontine adaptée à un objectif et répond en français, en anglais et en pidgin.

# Annexe A : Score de fiabilité et règle des premières places (proposition)

Un nouveau membre commence à 0. Valeurs de départ, à régler par simulation sur le scénario de démonstration (10 membres, un défaut).

| Événement | Points |
|---|---|
| Cotisation payée avant la date limite | +4 |
| Cotisation payée en retard, dans le délai de grâce | −1 |
| Défaut constaté (délai de grâce dépassé) | −30, et plus de première place au cycle suivant |
| Cycle terminé sans défaut | +10 |
| Départ avant la fin du cycle | −15 |

Le score reste entre 0 et 100. L'application affiche aussi le nombre de cycles terminés et de défauts, pour distinguer un nouveau d'un membre tombé à 0.

**Trois zones de passage.** Début de cycle : réservé aux scores supérieurs à un seuil qui monte avec la taille de la cagnotte (60 à 80 en proposition). Milieu : à partir d'un score modeste (30). Fin : ouvert à tous. Dans chaque zone, l'ordre suit le score, puis l'ordre d'inscription.

**Frais pour avancer.** Un membre éligible à une zone peut payer pour passer devant un autre membre de la même zone qui accepte de lui céder sa place ; celui qui cède reçoit une part des frais. Un score trop bas ne s'achète jamais.

Détail et cas limites : `docs/conception/score-et-places.md`.

# Annexe B : Journal des modifications par rapport à la première version

1. **Contexte** : ajout d'un quatrième problème, l'absence de recours légaux ; reformulation de la conclusion.
2. **Enjeux et objectifs** : « garantit les paiements » devient « réduit le risque de défaut » ; ajout de la signature et du dossier de preuve ; la blockchain devient un registre de règles et d'empreintes, sans fonds ; retenue et fonds de garantie renvoyés à la phase 2 ; Rota sert de source d'inspiration, l'ordre par score est à écrire.
3. **Score** : un nouveau membre commence à 0, avec affichage des cycles et des défauts (annexe A).
4. **Indicateurs SMART** : le défaut se mesure après un délai de grâce propre au cercle, plus de « + 7 jours » fixe ; ajout de l'indicateur des engagements opposables.
5. **Concurrence** : EAA reconnue comme concurrent proche ; la phrase « aucun concurrent ne combine les trois » est retirée ; positionnement reformulé ; limites de Rota précisées.
6. **User stories** : ajout du code secret et de la clé de signature, de la récupération du compte, du dossier de preuve ; parrainage sans caution ; frais d'avance limités à la même zone, avec part pour celui qui cède ; défaut constaté après délai de grâce.
7. **Non fonctionnelles** : signature par clé, registre sans donnée personnelle, conservation des pièces.
8. **Perspectives** : porte juridique avant le pilote réel ; réexamen de la retenue et du fonds de garantie au regard de l'article 13 de la loi 2010/021.

9. **Identité** : la vérification d'identité passe de V2 à MVP, en deux niveaux (téléphone et nom ; carte d'identité et selfie), simulée dans le prototype ; la vraie vérification reste en V2. Sans identité, le dossier de preuve ne désigne personne et un défaillant peut revenir avec une nouvelle carte SIM.

Ajouts non encore validés : l'absence de donnée personnelle sur la chaîne, l'indicateur des engagements opposables, l'affichage des cycles et des défauts à côté du score.
