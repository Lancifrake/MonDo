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

## Image Docker

```bash
# depuis la racine du dépôt
docker build -f src/serveur/Dockerfile -t mondo-serveur .
# essai local avec les simulateurs (hors production) :
docker run --rm -e NODE_ENV=demonstration -p 3000:3000 mondo-serveur
```

Image en deux étapes (construction, puis exécution avec les seules dépendances de production), utilisateur `node` sans droit d'écriture sur le code, contrôle de santé sur `/sante`. Par défaut `NODE_ENV=production` : le serveur refuse alors de démarrer sans `MONDO_STOCKAGE_CLE` et `MONDO_STOCKAGE_DOSSIER`, sans vrai fournisseur SMS et sans registre réel. C'est voulu : aucun simulateur en production. Le `.dockerignore` de la racine ne laisse entrer dans la construction que le serveur et les fichiers du monorepo. L'intégration continue construit l'image et vérifie `/sante` (job `image`). Choix de l'hébergeur et du fournisseur SMS : `docs/conception/comparatif-hebergeur-et-sms.md`.

## Démonstration

Hors production seulement (403 en production), pour montrer un cycle entier avec un seul téléphone. Le membre réel crée un cercle, puis, en tant qu'organisateur :

- `POST /demonstration/cercles/:id/membres-fictifs` : des membres fictifs complètent le cercle. Ils s'inscrivent, signent leur engagement et paient par les mêmes services que tout le monde, avec leur propre clé, gardée en mémoire (perdue au redémarrage).
- `POST /demonstration/cercles/:id/suite` : les membres fictifs paient le tour en cours et confirment ce qu'ils ont reçu, y compris le paiement du membre réel. Le dernier membre fictif cesse de payer après le premier tour : c'est le défaut de la démonstration.
- `POST /demonstration/cercles/:id/avance` (`jours`) : le temps du cercle avance (ses dates reculent), puis le planificateur passe : retards, défauts, pénalités, mises en demeure, fin de cycle.

`GET /assistant/mesures?lancements=100` : mesures du système multi-agents demandées par la grille d'évaluation, sur le scénario « 10 membres, un défaut », en mode autonome et en mode manuel : cycles, messages échangés, durée moyenne et maximale (cible : moins de 2 secondes), résultat identique à chaque lancement, mémoire.

## Structure

| Dossier                     | Rôle                                                           |
| --------------------------- | -------------------------------------------------------------- |
| `src/modules/comptes`       | inscription, clé publique, niveau d'identité                   |
| `src/modules/cercles`       | règlement signé, adhésions signées, ordre figé à la complétion |
| `src/modules/score`         | score = rejeu des événements                                   |
| `src/modules/cotisations`   | paiement déclaré, confirmé par le seul bénéficiaire            |
| `src/modules/planificateur` | rappels, défauts, SMS en file, lots du registre, chaque heure  |
| `src/modules/preuve`        | dossier de preuve et mises en demeure                          |
| `src/modules/litiges`       | litiges sur un paiement non confirmé, tranchés par l'admin     |
| `src/evenements`            | bus d'événements internes entre modules                        |
| `src/registre`              | arbre de hachage, inscription par lots (connecteur simulé)     |
| `src/signature`             | vérification ECDSA P-256, JSON canonique                       |
| `src/score`                 | règles pures : points, ordre de passage                        |
| `src/assistant`             | assistant multi-agents (décision 04)                           |
| `src/stockage`              | stockage d'objets chiffré (pièces d'identité)                  |
| `src/administration`        | qui est Administrateur (prototype : variable d'environnement)  |

## Règles

Un module ne lit que ses propres données et passe par les services exportés ou par les événements des autres. Les connecteurs externes restent simulés.

## Tours de cotisation

Générés d'un coup quand le cercle est complet (`src/modules/cotisations/calendrier.ts`), à partir du règlement signé et de l'ordre figé. On ne crée plus une cotisation à la main.

- **Date du premier tour** : champ `datePremierTour` du règlement, dans le futur à la création (choix de David, 05/11). Si le cercle se complète à cette date ou après, le départ est décalé d'autant de périodes qu'il faut.
- **Un tour par membre**, dans l'ordre de passage. Tours suivants : +7 jours en hebdomadaire, +N jours avec `frequence: "jours"` et `periodeJours: N` (de 1 à 60, au choix du cercle, par exemple 5 ou 14), même jour chaque mois en mensuel (le 31 devient le dernier jour des mois plus courts, sans dériver).
- **Délai de grâce plus court que la période** (7 jours en hebdomadaire, N en « jours », 28 en mensuel) : sinon le tour suivant commencerait avant que le défaut du précédent soit constaté. Un règlement qui ne le respecte pas est refusé.
- **Chaque membre doit le montant du règlement à chaque bénéficiaire sauf lui-même** : la cagnotte reçue vaut (nombre de membres − 1) × montant.
- **Fin de grâce** = date limite + délai de grâce du règlement, copiée sur chaque cotisation.
- `GET /cotisations?cercleId=…` : ce que le membre doit et ce qu'on lui doit dans ce cercle, rien sur les autres.

**Qui a payé, qui n'a pas payé** (US17) : `GET /cotisations/cercles/:cercleId/etat`, pour ceux qui paient ou reçoivent dans le cercle : chaque tour, son bénéficiaire, sa date limite et, pour chaque payeur, le statut, le retard, le litige et la pénalité due. Jamais la référence de la transaction.

**Score expliqué** (M6) : `GET /score/:membreId` ajoute `explication` (quelques phrases : ce qui fait monter, ce qui fait baisser, la règle des cercles privés), visible de ceux qui voient le score ; et, pour le membre lui-même seulement, `historique` : chaque événement avec sa date, son cercle, ses points et le score après lui.

**Lecture pour l'application** (requêtes signées, chacun ne lit que ce qui le concerne) : `GET /comptes/moi` (mon compte, sans la clé publique), `GET /cercles` (mes cercles : règlement, statut, nombre d'inscrits, ma place une fois l'ordre figé, jamais la liste des membres), `GET /litiges/miens` (les litiges où je suis payeur ou bénéficiaire).

**Identité** : niveau 1 à l'inscription (numéro vérifié par OTP, nom) ; niveau 2 exigé pour adhérer à un cercle ouvert à des inconnus. Le niveau 2 s'obtient par la vérification d'identité interne ci-dessous. `POST /comptes/:id/niveau2` reste un raccourci de démonstration et de test, qui n'examine aucune pièce : il est refusé en production (403).

**Contact de confiance** (choix de David, 11/11) : exigé au niveau 2, facultatif au niveau 1, aucun engagement financier. `POST /comptes/moi/contact-de-confiance` (nom, numéro) envoie au contact un SMS, par la file, avec un code à 6 chiffres ; s'il accepte, il donne le code au membre, qui le saisit par `POST /comptes/moi/contact-de-confiance/accord`. `GET /comptes/moi/contact-de-confiance` rend l'état (`en_attente` ou `accepte`). Code gardé haché, 5 essais, valable 48 h ; au plus 3 désignations par compte sur 24 h ; désigner un autre contact annule l'accord du précédent. Ces valeurs de sécurité sont des choix prudents, sans règle métier écrite. Limite : le contact ne peut pas retirer son accord lui-même (pas de SMS entrant).

**Choix de la place** (choix de David, 08/11) : `POST /cercles` et `POST /cercles/:id/adhesions` prennent `placeSouhaitee`, signée avec le règlement (organisateur) ou dans l'engagement (membre) : `messageReglement(organisateurId, reglement, place)` et `messageEngagement(cercleId, empreinteReglement, membreId, place)`. Refusée si elle sort du cercle ou si elle est plus tôt que ce que permet le score (`GET /cercles/:id` donne `premierePlaceAutorisee` au non-membre). Quand le cercle est complet, `attribuerLesPlaces` (`src/score/attribution-des-places.ts`) fige l'ordre : score prioritaire puis premier inscrit, place libre la plus proche permise et plutôt après en cas de conflit, places de tête restantes aux mieux classés de ceux qui n'ont rien trouvé. Chaque place de l'ordre garde la `placeSouhaitee` signée.

**Frais du modèle A** (choix de David, 11/11 ; règle détaillée dans `docs/conception/decision-05-choix-economiques-et-places.md`) : les places du début paient des frais sur la cagnotte nominale, 8 % pour la place 1, dégressif jusqu'à 0 % à la première place du milieu ; moitié pour MonDo, moitié en remise pour les places de fin, à parts égales. Le règlement signé porte le barème en francs (`bareme`, place par place) : `GET /cercles/bareme?nombreMembres=…&montant=…` le donne, et un règlement sans barème ou avec un barème inexact est refusé (`src/score/frais.ts`). Quand le cercle est complet, le module Cotisations crée les **sommes dues** : pour chaque bénéficiaire du début, sa part à MonDo et une remise à chaque membre d'une place de fin, exigibles le jour de sa cagnotte, à régler avant la date limite du tour suivant.

**Sommes dues** : suivies comme une cotisation. `GET /sommes-dues` (`?cercleId=` facultatif) : ce que je dois et ce qu'on me doit ; `POST /sommes-dues/:id/paiement` : celui qui doit déclare sa référence Mobile Money, pas avant l'exigibilité ; `POST /sommes-dues/:id/confirmation` : celui qui reçoit confirme (le membre créancier, ou un Administrateur pour la part de MonDo, jamais celui qui doit). `GET /administration/sommes-dues` : parts de MonDo déclarées, à confirmer. MonDo ne retient ni ne détient rien : il suit des paiements faits hors de lui. Au prototype, une somme impayée n'entraîne ni défaut, ni perte de score, ni mise en demeure.

**Ordre fixé en cercle privé** (choix de David, 11/11) : le règlement d'un cercle privé peut porter `ordreFixe`, la liste des identifiants des membres du premier au dernier (tous les membres, l'organisateur compris, des comptes existants, sans doublon). Refusé en cercle ouvert. Seuls les membres prévus adhèrent, chacun en signant la place que l'organisateur lui a fixée ; le score n'intervient pas, puisque tous signent l'ordre en le connaissant. À la complétion, l'ordre de passage est celui du règlement. Avec le lien, un membre prévu voit l'ordre et sa `placeFixee` ; un inconnu voit seulement `ordreFixeParOrganisateur: true`, jamais la liste. Pas de tirage au sort.

**Visibilité** (choix de David, 06/11) : `GET /cercles/:id` montre à un non-membre qui a le lien le règlement, son empreinte, le statut et les places restantes, jamais la liste des membres ni l'ordre de passage, réservés aux membres. `GET /score/:membreId` est réservé au membre lui-même et aux membres d'un cercle commun (le module Score tient sa propre copie des adhésions, par l'événement `adhesion_enregistree`).

**Défaut automatique** : le planificateur (`examinerEcheances`) constate le défaut d'une cotisation ni payée ni déclarée dès que sa fin de grâce est passée, une seule fois par tour (score −30, mise en demeure, assistant). Une cotisation déclarée mais pas confirmée par le bénéficiaire n'est jamais un défaut du payeur : elle relève d'un litige (voir Litiges). La mise en demeure est datée du constat et ne réclame que les cotisations échues à cette date, jamais les tours à venir.

**Pénalité de retard** (choix de David, 11/11) : elle revient au bénéficiaire du tour, une fois par cotisation, au montant du règlement, et devient due à la fin de grâce (au constat du défaut, datée de la fin de grâce). Un paiement tardif ne l'efface pas. Chaque cotisation porte `penalite` (montant du règlement), `penaliteDue` (0 tant qu'elle n'est pas due) et `penaliteDueLe` : le payeur et le bénéficiaire la voient par `GET /cotisations`, et le relevé du dossier de preuve la reprend. La mise en demeure détaille ses `lignes` par cotisation, avec le bénéficiaire de chacune, et ne compte une pénalité que pour les cotisations dont la fin de grâce est passée. MonDo ne suit pas le paiement de la pénalité elle-même.

**Départ en cours de cycle** (choix de David, 11/11 ; règle détaillée dans la décision 05) : `POST /cercles/:id/depart`, pour un membre d'un cercle complet qui n'a rien reçu de sa cagnotte (aucun paiement vers lui déclaré ou confirmé). Refusé s'il n'est pas à jour : cotisation échue impayée, paiement déclaré en attente, litige. Effets, en une transaction côté Cotisations : son tour et ses cotisations à venir passent à `annulee` (les dates des autres tours ne bougent pas) ; chaque bénéficiaire qu'il a déjà payé lui doit un remboursement, suivi comme une somme due (`remboursement_depart`, à régler sous une période) ; les frais et remises non réglés qui le concernent sont annulés, une remise déjà reçue est à rembourser. Puis : départ noté sur l'adhésion (`partis` dans le cercle), inscrit au registre, score −15, pas de bonus de fin de cycle pour lui, SMS aux autres membres. Non prévu : quitter un cercle pas encore complet, remplacer le membre parti.

**Cercles privés à moitié de points** (choix de David, 11/11) : dans un cercle privé, les gains comptent moitié moins (+2 pour une cotisation à temps, +5 pour un cycle terminé) ; les pertes restent entières (−1, −30, −15). Le module Score retient quels cercles sont privés (`score.cercles`, par l'événement `adhesion_enregistree`) et marque chaque événement (`cercle_prive`) ; le calcul reste un rejeu des événements (`pointsDe` dans `src/score/evenements.ts`). La migration applique la règle aux événements déjà enregistrés.

**Échange de places** (choix de David, 11/11) : après complétion, deux membres échangent leurs places. Gratuit au prototype. `POST /cercles/:id/echanges` (`avecMembreId`, `signature` de `messageEchange(cercleId, demandeurId, placeDemandeur, cedantId, placeCedant)`), puis le membre visé répond par `POST /cercles/:id/echanges/:echangeId/acceptation` (sa signature du même message) ou `/refus` ; `GET /cercles/:id/echanges` liste mes échanges. Règles, vérifiées à la proposition et de nouveau à l'acceptation : celui qui avance doit y avoir droit par son score (reculer est toujours permis) ; la proposition expire 48 h après sans seconde signature ; l'acceptation est suspendue (409) tant qu'un des deux comptes est en récupération ; aucun des deux tours n'a commencé ; jamais dans un cercle à ordre fixé. À l'acceptation, les tours, les cotisations et les frais non réglés du modèle A sont permutés en une transaction (les frais suivent la place), l'ordre du cercle est mis à jour, l'échange est inscrit au registre et les membres sont prévenus par SMS.

**Passage régulier** : au démarrage du serveur (`main.ts`), le planificateur passe une première fois pour rattraper un arrêt, puis toutes les heures. Chaque passage enchaîne trois étapes indépendantes : échéances, SMS restés en file, puis registre (lots en échec réinscrits, puis le lot en cours fermé et sa racine inscrite sur la chaîne, soit au plus une transaction par heure). Jamais deux passages en même temps ; une étape en échec est journalisée, les suivantes ont lieu quand même et elle est reprise au passage suivant (chaîne en panne : le lot reste figé en base) ; à l'arrêt, le passage en cours se termine avant la fermeture de la base. Les tâches étant rejouables, passer souvent ou sur plusieurs instances ne double ni un rappel ni un défaut.

- `MONDO_PLANIFICATEUR_MINUTES` : intervalle en minutes (60 par défaut), `0` pour désactiver ; une valeur invalide empêche le démarrage.
- Les tests ne démarrent pas la minuterie : ils appellent `examinerEcheances` avec leur propre date.

**Fin de cycle** (choix de David, 05/11) : bonus « cycle terminé » (+10) pour un membre quand la fin de grâce du dernier tour est passée, qu'il n'a eu aucun défaut dans ce cercle (même régularisé ensuite) et que le bénéficiaire a confirmé toutes ses cotisations. S'il manque une confirmation, le bonus arrive au passage qui suit. Une seule fois par membre et par cercle.

**Cercle terminé** (choix de David, 05/11) : à la fin de grâce du dernier tour, le planificateur passe le cercle au statut `termine` (date `termineLe` = cette fin de grâce), une seule fois, impayés ou non. Défauts, mises en demeure, litiges et dossier de preuve continuent après. La fin est inscrite au registre ; plus aucune adhésion.

## Vérification d'identité (niveau 2)

Faite en interne, sans prestataire (choix de David, 08/11 et 11/11).

1. Le membre a un contact de confiance qui a donné son accord (sinon 403).
2. `GET /comptes/moi/identite/consentement` rend le texte de consentement et sa version. `POST /comptes/moi/identite` dépose `typePiece` (`cni` ou `passeport`), `recto`, `verso`, `selfie` (JPEG ou PNG en base64, 2 Mo chacun au plus), avec `consentement: true` et `versionConsentement`. Le consentement est daté et gardé avec le dossier. Un seul dossier en attente par compte, 3 dépôts par jour au plus.
3. Un Administrateur (`MONDO_ADMINISTRATEURS`) consulte la file `GET /administration/identites`, ouvre une pièce par `GET /administration/identites/:id/pieces/:nature` (chaque ouverture est journalisée dans `comptes.acces_pieces`) et décide par `POST /administration/identites/:id/decision` (`validee` ou `refusee`, avec un motif). Il ne traite jamais son propre dossier.
4. Décision `validee` : niveau 2, selfie supprimé tout de suite, carte gardée chiffrée. Décision `refusee` : toutes les images sont supprimées, le motif est rendu au membre par `GET /comptes/moi/identite`, un nouveau dépôt est possible. La décision est inscrite au registre (empreinte, sans le motif) et le membre est prévenu par SMS.
5. Conservation : la carte est supprimée 5 ans après la décision ou la fin du dernier cercle du membre, jamais tant qu'il a un cercle en cours (durée provisoire, à valider par un juriste). Le planificateur fait cette purge à chaque passage et reprend une suppression manquée.

**Stockage des images** : derrière l'interface `StockageObjets` (`src/stockage`), jamais en base ni dans les journaux. Au prototype, un fichier par image, chiffré en AES-256-GCM, dans `MONDO_STOCKAGE_DOSSIER`, avec la clé `MONDO_STOCKAGE_CLE` (32 octets en base64, par exemple `openssl rand -base64 32`). Sans ces deux variables, hors production, la clé et le dossier sont temporaires ; en production, le serveur refuse de démarrer. Perdre la clé rend les pièces illisibles : elle se sauvegarde à part.

Le corps des requêtes reste limité à 100 ko, sauf pour le dépôt des pièces (9 Mo), lu par `src/application.ts`.

## Récupération de compte et compte bloqué

Flow 2, délais choisis par David (08/11 et 11/11).

- **Code secret** : `POST /comptes/moi/code-secret` (4 à 8 chiffres, requête signée). Gardé haché (scrypt), jamais en clair.
- **Demande** depuis le nouveau téléphone : `POST /comptes/recuperation`, sans requête signée puisque l'ancienne clé est perdue. Elle est prouvée par le code SMS du numéro, le code secret et la détention de la nouvelle clé (`messageRecuperation`). Toute erreur donne la même réponse 403, sans dire si le numéro existe. Une seule demande en cours par compte.
- **Avec un contact de confiance** qui a donné son accord, et le bon code secret : délai de **48 h**. Le titulaire (SMS sur son numéro) et le contact sont prévenus.
- **Sans contact**, ou sans code secret défini : délai de **72 h**, plus carte d'identité et selfie, déposés par `POST /comptes/recuperation/:id/pieces` (prouvés par la nouvelle clé, `messagePiecesRecuperation`) et validés par un Administrateur dans la même file que le niveau 2. Ces images sont toutes supprimées dès la décision. Sans pièces validées, la demande s'éteint 7 jours après la fin du délai.
- **Fin du délai** sans opposition : le planificateur remplace la clé (`RecuperationService.finaliser`, rejouable). L'ancienne clé est gardée comme clé révoquée : les documents signés avant restent vérifiables, et le dossier de preuve les liste (`clesRevoquees`). Le changement est inscrit au registre (empreintes des clés).
- **Opposition** : le titulaire, avec son ancienne clé, voit la demande (`GET /comptes/moi/recuperation`) et s'y oppose (`POST /comptes/moi/recuperation/opposition`). Le compte est alors bloqué et le dossier part chez l'Administrateur : `GET /administration/recuperations`, puis `POST /administration/recuperations/:id/decision` (`titulaire_confirme` ou `recuperation_acceptee`, avec un motif), qui débloque le compte. Un Administrateur ne tranche jamais pour son propre compte.
- **Compte bloqué** (règle du 03/11) : seulement après une opposition (levé par l'Administrateur) ou après 5 codes secrets faux en 24 h (levé par le temps, 24 h). Un compte bloqué ne peut plus agir : toute requête signée reçoit 423. Ses cotisations ne donnent ni rappel, ni retard, ni défaut ; au déblocage, leurs dates limites et fins de grâce reculent de la durée du blocage. Les autres membres de ses cercles en cours sont prévenus par SMS au blocage et au déblocage, sans que le message le nomme.

Valeurs choisies par prudence, sans règle écrite : 5 codes secrets faux, blocage de 24 h, extinction à 7 jours. Non fait : gel du numéro de réception de la cagnotte après une récupération (flow 2), puisque le compte n'a qu'un numéro.

## Litiges

Sur un paiement déclaré que le bénéficiaire ne confirme pas (règles choisies par David, 05/11) :

- **Ouverture** : par le payeur, 48 h après sa déclaration ; par le bénéficiaire qui dit n'avoir rien reçu, tout de suite ; ou automatiquement par le planificateur à la fin de grâce. Un seul litige ouvert par cotisation. Un paiement déclaré n'est jamais un défaut. Pendant un litige ouvert, la déclaration est gelée : le payeur ne change plus sa référence, l'administrateur tranche sur la pièce d'origine ; le bénéficiaire peut toujours confirmer (choix de David, 06/11).
- **Décision** par un administrateur, jamais partie au litige : `paiement_valide`, la cotisation est confirmée (à temps si elle avait été déclarée avant la date limite) ; `paiement_refuse`, elle redevient due ; si la fin de grâce est passée, le défaut est constaté dès la décision (choix de David, 06/11 : une fausse redéclaration avant le passage du planificateur ne l'évite plus), sinon le payeur peut encore payer et redéclarer. Aucune pénalité pour le bénéficiaire au prototype : la décision reste tracée.
- **Relance du bénéficiaire** (flow 6) : tant qu'un paiement déclaré n'est ni confirmé ni en litige, le bénéficiaire reçoit un SMS 24 h après la déclaration, puis un second à 48 h. Rejouable (une tâche par palier et par déclaration) ; après un arrêt de deux jours, seul le second part. Le SMS donne le montant et le tour, jamais le nom du payeur ni la référence.
- **Clôture** : si le bénéficiaire finit par confirmer lui-même, le litige est clos sans décision.
- Ouverture et décision sont inscrites au registre (empreintes).
- Routes : `POST /litiges`, `GET /litiges/:id` (parties et administrateur), `GET /litiges` et `POST /litiges/:id/decision` (administrateur).
- **Administrateurs** (prototype) : identifiants de comptes membres dans `MONDO_ADMINISTRATEURS`, séparés par des virgules. Une vraie administration web viendra plus tard.

- **SMS aux deux parties** à l'ouverture (avec le numéro de suivi, début de l'identifiant du litige), à la décision (un refus dit au payeur de régler vite pour éviter un défaut) et à la clôture.

Non fait : pièces jointes (capture du reçu Mobile Money), administration web.

## File d'envoi des SMS

Décision 02, règle 4 : un SMS est d'abord écrit en base (`sms.envois`), puis envoyé en arrière-plan. Une panne de la passerelle ne bloque donc ni un litige ni une cotisation.

- Envoi tenté tout de suite, puis à chaque passage du planificateur pour ceux restés en file ; abandon après 5 échecs, journalisé sans le numéro.
- Clé unique par message : un événement rejoué ne donne qu'un SMS. Chaque message est réservé avant l'envoi : deux serveurs ne l'envoient pas deux fois ; une réservation de plus de 5 minutes (serveur arrêté en route) est reprise.
- Le code de connexion (OTP) part en direct, sans file : le membre l'attend et doit savoir s'il est parti.
- Passerelle simulée au prototype (fournisseur non choisi).
- Passent par la file : les SMS de litige, et ceux de l'assistant (rappel avant l'échéance, rappel de retard, mise en demeure), en mode autonome tout de suite, en mode manuel après l'accord de l'organisateur. Le texte est rédigé au moment de l'envoi : un rappel ne part pas si la cotisation visée a été payée ou déclarée entre-temps. La mise en demeure est marquée envoyée une fois remise à la file.
- Montants écrits avec une espace ordinaire (10 000 FCFA) pour rester dans l'alphabet GSM (160 caractères par SMS) ; dates à l'heure du Cameroun.

## Registre lisible et vérifiable

Chaque empreinte inscrite garde, à côté d'elle, le type de l'événement et le cercle concerné (jamais de contenu, jamais de donnée personnelle). `GET /cercles/:id/registre`, pour les membres du cercle (y compris ceux qui en sont partis) :

- les événements du cercle (règlement, engagements, ordre, nouvel ordre après un échange, départs, litiges, mises en demeure, fin) avec leur empreinte, leur lot, la transaction d'inscription et la preuve d'inclusion, vérifiable avec la racine et la fonction `verifierInclusion` du contrat, sans faire confiance à MonDo ;
- la vérification de chaque lot : la racine recalculée à partir des empreintes en base doit être celle du lot, et cette racine doit être inscrite sur la chaîne (relue sur le contrat) ;
- la vérification des documents : le règlement, l'ordre et les engagements tels qu'ils sont en base doivent correspondre à des empreintes inscrites ;
- `integre` : faux dès qu'une empreinte, une racine, le règlement ou l'ordre a été retouché à la main (scénario S8 du cahier des charges).

Statut d'un événement : `en_attente` (pas encore dans un lot), `non_inscrite` (lot figé, inscription à reprendre), `inscrite`, `alteree`.

Pour le voir sur une vraie chaîne sans réseau public : `corepack pnpm chaine-locale` dans `src/contrat`, puis lancer le serveur avec la ligne affichée.

## Dossier de preuve

`GET /preuve/cercles/:cercleId/membres/:membreId/dossier`, réservé aux autres membres du cercle, seulement après un défaut constaté. Contient : identité du débiteur, règlement et engagement signés (vérifiables avec les clés publiques), preuves d'inscription au registre, relevé des cotisations, mises en demeure. L'export lui-même est inscrit au registre.

Non fait, en attente de décision : reconnaissance de dette (créancier et montant à trancher avec un juriste), clôture du dossier après régularisation (MonDo ne suit pas le paiement des pénalités), envoi réel de la mise en demeure (SMS par la passerelle simulée), export PDF.

## Inscription

1. `POST /comptes/otp` avec le numéro : un code à 6 chiffres part par SMS (simulé : visible dans le journal du serveur).
2. `POST /comptes` avec numéro, nom, clé publique, preuve de détention de la clé et code SMS.
3. Ensuite, chaque requête est signée par le téléphone (ECDSA P-256) : en-têtes `x-mondo-membre`, `x-mondo-horodatage` et `x-mondo-signature`, sur la méthode, le chemin, l'horodatage et le corps en JSON canonique. Une requête vaut 5 minutes et une seule fois : l'anti-rejeu retient l'empreinte du message signé, pas le texte de la signature, qui s'écrit de plusieurs façons valides.

Limites des codes SMS : un code par minute et par numéro tant que le précédent n'a pas servi, au plus 5 codes par numéro sur 24 h, 5 essais par code, validité 5 minutes. Les contrôles et l'écriture se font en une seule instruction : deux demandes simultanées ne passent pas toutes les deux. Une limite par adresse IP reste à poser chez l'hébergeur (voir `docs/conception/audit-securite-2026-11-06.md`).
