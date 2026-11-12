# Audit de sécurité du prototype, 06/11/2026

Relecture du serveur (`src/serveur`), du contrat (`src/contrat`) et de l'intégration continue, à l'état de `main` après la PR 18. Audit interne fait par Claude Code : il ne remplace ni un audit indépendant du contrat ni un test d'intrusion, obligatoires avant tout pilote réel (SECURITY.md).

## Résumé
- 2 failles réelles trouvées dans le code, corrigées : rejeu de requête signée (élevée), absence de plafond sur les codes SMS (moyenne).
- 2 trous corrigés juste avant, dans la PR 18 : lots du registre jamais inscrits sur la chaîne, niveau 2 d'identité auto-déclaré même en production.
- 2 durcissements mineurs, corrigés : jeton de la CI en lecture seule, en-tête `x-powered-by` retiré.
- 3 points de règle métier, tranchés par David le 06/11 et codés (PR suivante).
- Rien de grave relevé dans le contrat, les requêtes SQL ou les contrôles d'accès.

## Failles corrigées

### 1. Rejeu d'une requête signée (élevée), corrigée
L'anti-rejeu retenait le texte base64 de la signature. Or une même signature s'écrit de plusieurs façons valides : padding retiré ou ajouté, espace en tête, et surtout malléabilité ECDSA (s remplacé par n − s donne une seconde signature valide du même message). Quelqu'un qui interceptait une requête pouvait la rejouer pendant 5 minutes, par exemple une déclaration de paiement ou une adhésion.
Correction : l'anti-rejeu retient l'empreinte SHA-256 du membre et du message signé (méthode, chemin, horodatage, corps). Migration `015_requetes_vues`. Tests : trois variantes d'encodage et la signature malléable sont refusées.

### 2. Codes SMS sans plafond (moyenne), corrigée
Un code par minute et par numéro, sans autre limite : 1 440 SMS par jour vers un même numéro (harcèlement, coût) et un code neuf chaque minute pour deviner. Le contrôle « une minute » était aussi lu puis écrit en deux temps : deux demandes simultanées passaient toutes les deux.
Correction : au plus 5 codes par numéro sur 24 h glissantes, contrôles et écriture en une seule instruction SQL. Migration `016_plafond_otp`. Tests : sixième code refusé jusqu'au lendemain, trois demandes simultanées donnent un seul SMS.
Reste à faire chez l'hébergeur : une limite par adresse IP (un attaquant peut encore viser des milliers de numéros différents). Elle dépend du mandataire inverse (adresse réelle du client), donc de l'hébergement, pas encore choisi.

### 3. Lots du registre jamais inscrits (PR 18), corrigée
`fermerLot` n'était appelé que par les tests : rien ne partait sur la chaîne. Le planificateur ferme et inscrit désormais un lot à chaque passage, et réinscrit les lots en échec.

### 4. Niveau 2 d'identité auto-déclaré (PR 18), corrigée
`POST /comptes/:id/niveau2` donnait le niveau 2 sans aucune pièce, y compris en production. Refusé en production tant qu'aucun prestataire de vérification n'est branché.

### 5. Durcissements mineurs, corrigés
- Intégration continue : `permissions: contents: read`, le jeton ne peut plus écrire dans le dépôt.
- Serveur : l'en-tête `X-Powered-By: Express` n'est plus envoyé (vérifié par l'essai de démarrage).

## Points vérifiés sans constat
- **Authentification** : toute route exige une requête signée sauf `/sante`, `POST /comptes/otp` et `POST /comptes` ; identité lue dans la signature, jamais dans le corps ; horodatage à plus ou moins 5 minutes ; chemin et paramètres inclus dans le message signé.
- **Inscription** : preuve de détention de la clé, code SMS vérifié avant de dire si le numéro existe, code stocké haché et salé, comparaison à temps constant, essai compté avant la comparaison.
- **Contrôles d'accès** : déclarer (payeur seul), confirmer (bénéficiaire seul), litige (parties et administrateur, jamais un administrateur partie), assistant (organisateur seul), dossier de preuve (autres membres du cercle, après un défaut), niveau 2 (soi-même).
- **Concurrence** : dernière place d'un cercle (verrou de ligne), confirmations et décisions (mises à jour conditionnelles), constats rejouables (tâches traitées), file SMS (`FOR UPDATE SKIP LOCKED`).
- **Injection SQL** : toutes les requêtes sont paramétrées, aucune concaténation de valeur.
- **Validation** : chaque corps passe par un schéma Zod strict (champs inconnus refusés, bornes sur les montants et les textes).
- **Fuites** : erreurs 500 sans détail technique, `/sante` sans détail, numéro absent des journaux de la file SMS, SMS et registre simulés interdits en production.
- **Contrat** : rôles OpenZeppelin, une seule inscription par racine, refus de tout envoi d'argent, arrêt d'urgence, vérification d'inclusion identique au serveur (test croisé), Slither sans constat.
- **Secrets** : aucun dans le dépôt ni dans l'historique relu, `.env`, `.pem` et `.key` ignorés, clés lues dans l'environnement seulement.
- **Dépendances de production** : `pnpm audit --prod` sans vulnérabilité connue (serveur et contrat).

## Règles métier tranchées par David (06/11), codées
1. **Déclaration gelée pendant un litige ouvert.** Le payeur ne change plus sa référence tant que l'administrateur n'a pas tranché ; il tranche sur la pièce d'origine. Le bénéficiaire peut toujours confirmer, ce qui clôt le litige. Colonne `en_litige` (migration 017), posée à l'ouverture, levée à la décision ou à la confirmation.
2. **Défaut dès le refus.** Après un « paiement refusé », si la fin de grâce est passée, le défaut est constaté tout de suite, avec la même tâche que le planificateur (jamais deux défauts pour un tour). Avant la fin de grâce, le payeur peut encore payer et redéclarer.
3. **Visibilité.** Cercle : avec le lien, un non-membre voit le règlement, son empreinte, le statut et les places restantes ; la liste des membres et l'ordre de passage sont réservés aux membres. Score : visible par le membre lui-même et par les membres d'un cercle commun (copie des adhésions dans le module Score, migration 018).

## Hors code, avant un pilote réel
- Audit indépendant du contrat, test d'intrusion du serveur.
- GitHub : protection de `main`, Dependabot, CodeQL, alertes de secrets, signalement privé (SECURITY.md).
- Hébergement : HTTPS obligatoire, limite par adresse IP sur `POST /comptes/otp` et `POST /comptes`, base chiffrée au repos, sauvegardes.
- Clé du compte inscripteur du registre : portefeuille dédié, peu d'ETH, rôle retirable par l'administrateur.
- Vrai prestataire de vérification d'identité et stockage chiffré des pièces (SECURITY.md, règle 7).
- Dépendances de développement : deux alertes (minimatch par ESLint, zod par Hardhat), sans effet sur le serveur en production ; à suivre lors des mises à jour.

## Passe du 12/11/2026 sur les ajouts des 11 et 12/11
Relecture de ce qui a été ajouté depuis le 06/11 (PR 27 à 38) : routes de lecture, relance du bénéficiaire, contact de confiance, vérification d'identité interne et stockage chiffré, récupération de compte et compte bloqué, ordre fixé, frais et sommes dues, pénalité, départ, demi-points, échange de places, image Docker. Même limite que ci-dessus : audit interne, qui ne remplace ni un test d'intrusion ni un audit indépendant.

### Corrigé pendant cette passe
1. **Gros corps de requête refusé trop tard (moyenne).** Les deux routes qui acceptent 9 Mo (dépôt des pièces) lisaient le corps avant de le refuser. Une taille annoncée au-delà de la limite est maintenant refusée (413) sans lire un octet ; un corps qui dépasse en cours de route n'est plus gardé en mémoire.
2. **Rejeu du dépôt de pièces d'une récupération (faible).** Cette route n'est pas couverte par la garde, puisque l'ancienne clé est perdue : sa preuve, signée par la nouvelle clé et valable 5 minutes, pouvait être renvoyée. Elle passe désormais par le même anti-rejeu que les requêtes signées.
3. **Propositions d'échange en série (faible).** Chaque proposition envoie un SMS au membre visé, et rien ne limitait le cycle proposer, refuser, proposer. Plafond de 3 propositions par demandeur et par cercle sur 24 h.
4. **Départ interrompu (faible, fiabilité).** Une panne entre l'annulation des cotisations et la note du départ laissait le membre coincé : cotisations annulées, mais toujours membre, et toute nouvelle demande refusée. La demande rejouée termine maintenant le départ, avec un seul retrait de points.

### Droits de chaque nouvelle route (tous couverts par un test « qui a le droit, qui ne l'a pas »)
| Route | Qui |
|---|---|
| `GET /comptes/moi`, `GET /cercles`, `GET /litiges/miens`, `GET /sommes-dues` | le membre, pour ses propres données seulement |
| `/comptes/moi/contact-de-confiance` (lecture, désignation, accord) | le membre, pour son propre contact |
| `POST /comptes/moi/identite`, `GET /comptes/moi/identite` | le membre, pour son propre dossier ; contact consentant exigé |
| `/administration/identites` (file, pièce, décision) | Administrateur, jamais pour son propre dossier ; chaque ouverture de pièce est journalisée |
| `POST /comptes/moi/code-secret`, `GET /comptes/moi/recuperation`, `POST /comptes/moi/recuperation/opposition` | le titulaire, avec sa clé actuelle |
| `POST /comptes/recuperation` | sans signature : code SMS du numéro, code secret, preuve de détention de la nouvelle clé |
| `POST /comptes/recuperation/:id/pieces` | sans signature : preuve signée par la nouvelle clé de cette demande, 5 minutes, usage unique |
| `/administration/recuperations` (file, décision) | Administrateur, jamais pour son propre compte |
| `GET /cercles/bareme` | tout membre authentifié (calcul public) |
| `POST /sommes-dues/:id/paiement` | celui qui doit la somme, pas avant l'exigibilité |
| `POST /sommes-dues/:id/confirmation` | celui qui la reçoit ; pour la part de MonDo, un Administrateur qui n'est pas le débiteur |
| `GET /administration/sommes-dues` | Administrateur |
| `POST /cercles/:id/depart` | un membre actuel du cercle, pour lui-même |
| `/cercles/:id/echanges` (liste, proposition) | un membre actuel du cercle ; chacun ne liste que ses échanges |
| `/cercles/:id/echanges/:id/acceptation` et `/refus` | le membre visé seulement, avec sa signature du même message |

Toute requête d'un compte bloqué reçoit 423. Les corps passent par un schéma Zod strict. Les deux seules routes ajoutées sans signature sont celles de la récupération.

### Concurrence vérifiée par des tests
Décision d'identité, confirmation d'une somme due, départ, acceptation d'un échange : deux requêtes simultanées, une seule passe (mise à jour conditionnelle ou ligne unique). Un seul dossier d'identité en attente, une seule récupération en cours, un seul blocage en cours, une seule proposition d'échange en cours : garantis par des index uniques. Désignation d'un contact et compteur d'échecs du code secret : contrôle et écriture en une instruction.

### Fuites vérifiées
- Images d'identité : jamais en base, jamais dans les journaux, jamais dans une réponse sauf à l'Administrateur qui ouvre une pièce en attente. Nom de fichier sans rapport avec le contenu, chiffrement lié au nom de l'objet.
- Registre : décisions d'identité, récupérations, départs et échanges y entrent par leur empreinte ; les clés par leur empreinte ; aucun motif, aucun numéro.
- SMS : relance, blocage, départ et échange ne nomment pas les autres membres ; aucune référence de transaction.
- La récupération répond pareil que le numéro existe ou non. Un non-membre ne voit pas l'ordre fixé d'un cercle privé.
- Image Docker : utilisateur non root, contexte de construction réduit au serveur, aucun secret dans l'image.

### Limites connues, non corrigées
1. **Carte SIM volée ou réattribuée.** Le SMS qui prévient le titulaire d'une récupération part sur le numéro, que l'attaquant contrôle alors. Les vraies protections sont le code secret, le délai, le contact de confiance et, sans contact, la validation des pièces par un Administrateur. Il manque une alerte dans l'application de l'ancien téléphone (notification), qui dépend du client mobile.
2. **Blocage répété.** Qui détient la carte SIM d'un membre peut bloquer son compte 24 h en donnant 5 codes secrets faux, et recommencer. Ses échéances sont suspendues pendant ce temps, donc sans perte pour lui, mais le cercle attend.
3. **Code d'accord du contact de confiance** : il est en clair dans la file d'envoi des SMS (`sms.envois`) le temps de l'envoi et après. Un accès en lecture à la base permettrait d'enregistrer un accord à la place du contact. À traiter avec la purge de la file.
4. **Mémoire sous charge.** 9 Mo par dépôt de pièces, avant toute authentification sur la route de récupération : une limite par adresse IP chez l'hébergeur reste nécessaire, comme pour les codes SMS.
5. **Pas de boîte d'envoi transactionnelle.** Un arrêt du serveur entre deux étapes d'une action qui touche plusieurs modules (échange accepté puis tours permutés, départ noté puis événement de score) peut laisser un état partiel. Les étapes sont ordonnées pour que l'argent suivi reste cohérent et que la reprise soit possible, mais ce n'est pas atomique. Défaut connu depuis le 03/11.
6. **Clé du stockage** : une seule clé, sans rotation ; la perdre rend les pièces illisibles, la laisser fuir les expose toutes.
7. **Administrateurs** : toujours des comptes membres listés dans une variable d'environnement, sans double validation ni journal de toutes leurs actions (seules les ouvertures de pièces et les décisions sont tracées).
8. Les requêtes nouvelles du plafond d'échanges n'ont été exercées que sur la base embarquée ; le reste a tourné sur un vrai PostgreSQL local.

### Hors code, en plus de la liste du 06/11
- Avis d'un juriste sur les données personnelles avant tout membre réel (`docs/juridique/protection-des-donnees.md`).
- Sauvegarde séparée de `MONDO_STOCKAGE_CLE` et du dossier des pièces.
- Limite par adresse IP sur `POST /comptes/recuperation` et sur les deux routes de dépôt.

