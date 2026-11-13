# Contrat d'API du serveur MonDo

Date : 13/11/2026. Pour l'équipe qui construit l'application mobile et l'administration web. Liste tirée du code (66 routes) ; le détail des règles est dans `src/serveur/README.md`.

## Signer une requête

Toute route est signée, sauf les quatre marquées « publique ». Le téléphone crée une clé ECDSA P-256 ; seule la clé publique (JWK) part au serveur, à l'inscription. Chaque requête porte trois en-têtes :

- `x-mondo-membre` : l'identifiant du compte ;
- `x-mondo-horodatage` : la date ISO 8601 ;
- `x-mondo-signature` : la signature, au format r||s en base64 (celui de WebCrypto), du JSON canonique (clés triées) de `{ methode, chemin, horodatage, corps }`. `corps` vaut `null` quand il est vide ; `chemin` comprend les paramètres de requête.

Une requête vaut 5 minutes et une seule fois : deux requêtes identiques doivent avoir des horodatages différents. Un compte bloqué reçoit 423. Les corps sont validés strictement : un champ inconnu donne 400.

Messages signés en plus de la requête : `messageInscription`, `messageReglement`, `messageEngagement`, `messageEchange`, `messageRecuperation`, `messagePiecesRecuperation` (`src/serveur/src/authentification/messages.ts` et `modules/cercles/cercles.service.ts`). Le serveur fait foi pour leur texte exact.

Codes de réponse : 400 entrée invalide ou règle métier, 401 non signée ou signature invalide, 403 pas le droit, 404 introuvable (ou pas à vous), 409 conflit (déjà en cours), 413 corps trop gros, 423 compte bloqué, 429 trop de demandes.

## Routes

### Compte et identité
| Méthode | Chemin | Qui | Rôle |
|---|---|---|---|
| POST | /comptes/otp | publique | code SMS (5 par numéro et par jour) |
| POST | /comptes | publique | inscription : numéro, nom, clé publique, preuve, code SMS |
| GET | /comptes/moi | soi | mon compte |
| GET, POST | /comptes/moi/contact-de-confiance | soi | lire ou désigner mon contact de confiance |
| POST | /comptes/moi/contact-de-confiance/accord | soi | code transmis par le contact |
| GET | /comptes/moi/identite/consentement | soi | texte de consentement en vigueur |
| GET, POST | /comptes/moi/identite | soi | mon dossier ; dépôt recto, verso, selfie (9 Mo au plus) |
| POST | /comptes/moi/code-secret | soi | code secret de récupération |
| POST | /comptes/recuperation | publique | demande depuis un nouveau téléphone |
| POST | /comptes/recuperation/:id/pieces | publique | pièces de la demande, signées par la nouvelle clé |
| GET | /comptes/moi/recuperation | soi | récupération en cours sur mon compte |
| POST | /comptes/moi/recuperation/opposition | soi | je m'y oppose |
| GET, POST | /comptes/moi/parrainages | soi | mes parrainages ; en proposer un |
| POST | /comptes/moi/parrainages/:id/acceptation, /refus | le filleul | répondre |
| POST | /comptes/:id/niveau2 | soi | raccourci de démonstration, refusé en production |

### Cercles
| Méthode | Chemin | Qui | Rôle |
|---|---|---|---|
| GET | /cercles/bareme | membre | barème des frais à signer |
| POST | /cercles | membre | créer (règlement signé, place souhaitée, `cerclePrecedentId` pour un cycle suivant) |
| GET | /cercles | soi | mes cercles |
| GET | /cercles/catalogue | membre | cercles ouverts qui cherchent des membres |
| GET | /cercles/:id | membre | règlement et statut ; membres et ordre réservés aux membres |
| POST | /cercles/:id/adhesions | membre | rejoindre (engagement signé) |
| POST | /cercles/:id/invitations | organisateur | inviter un numéro par SMS |
| POST | /cercles/:id/depart | membre du cercle | partir avant d'avoir reçu |
| GET | /cercles/:id/registre | membre du cercle | registre et vérification d'intégrité |
| GET, POST | /cercles/:cercleId/echanges | membre du cercle | mes échanges ; en proposer un |
| POST | /cercles/:cercleId/echanges/:id/acceptation, /refus | membre visé | répondre |

### Cotisations, frais, score
| Méthode | Chemin | Qui | Rôle |
|---|---|---|---|
| GET | /cotisations?cercleId= | soi | ce que je dois et ce qu'on me doit |
| GET | /cotisations/cercles/:cercleId/etat | membre du cercle | qui a payé, tour par tour |
| POST | /cotisations/:id/paiement | payeur | déclarer un paiement (référence) |
| POST | /cotisations/:id/confirmation | bénéficiaire | confirmer la réception |
| POST | /cotisations/:id/paiement-simule | payeur | Mobile Money simulé, hors production |
| GET | /cotisations/:id/paiements-simules | payeur, bénéficiaire | tentatives |
| GET | /sommes-dues | soi | frais, remises, remboursements |
| POST | /sommes-dues/:id/paiement | débiteur | déclarer |
| POST | /sommes-dues/:id/confirmation | créancier ou Administrateur | confirmer |
| GET | /score/:membreId | soi, membres d'un cercle commun | score, explication ; historique pour soi |

### Litiges, preuve, assistant, notifications
| Méthode | Chemin | Qui | Rôle |
|---|---|---|---|
| POST | /litiges | payeur, bénéficiaire | ouvrir |
| GET | /litiges/miens | soi | mes litiges |
| GET | /litiges/:id | parties, Administrateur | lire |
| GET | /preuve/cercles/:cercleId/membres/:membreId/dossier | autres membres du cercle | dossier de preuve après un défaut |
| POST | /assistant/cercles/:cercleId/mode | organisateur | autonome ou manuel |
| GET | /assistant/cercles/:cercleId/journal | organisateur | actions et propositions |
| POST | /assistant/propositions/:id/acceptation, /refus | organisateur | décider (mode manuel) |
| GET | /assistant/mesures | membre | mesures multi-agents pour la grille |
| GET | /notifications | soi | ma boîte |
| POST | /notifications/:id/lue, /notifications/lues | soi | marquer lu |

### Administration (comptes listés dans `MONDO_ADMINISTRATEURS`)
| Méthode | Chemin | Rôle |
|---|---|---|
| GET | /litiges ; POST /litiges/:id/decision | litiges ouverts ; trancher |
| GET | /administration/identites ; GET …/:id/pieces/:nature ; POST …/:id/decision | vérification d'identité |
| GET | /administration/recuperations ; POST …/:id/decision | récupérations contestées |
| GET | /administration/sommes-dues | parts de MonDo à confirmer |

### Démonstration et exploitation
| Méthode | Chemin | Qui | Rôle |
|---|---|---|---|
| POST | /demonstration/cercles/:cercleId/membres-fictifs, /suite, /avance | organisateur, hors production | jouer un cycle complet avec un seul téléphone |
| GET | /sante | publique | santé du serveur et de la base |

## Correspondance avec le cahier des charges (section 8)

Les noms du cahier étaient des propositions ; voici les routes réelles.

| Cahier des charges | Serveur |
|---|---|
| POST /auth/otp, POST /auth/verify | POST /comptes/otp, POST /comptes (pas de session : chaque requête est signée) |
| POST /tontines | POST /cercles |
| POST /tontines/{id}/invitations | POST /cercles/:id/invitations |
| POST /tontines/{id}/join | POST /cercles/:id/adhesions |
| GET /tontines/{id}/ordre | GET /cercles/:id (champ `ordre`, membres seulement) |
| POST /paiements/declarer, /confirmer | POST /cotisations/:id/paiement, /confirmation |
| GET /membres/{id}/score | GET /score/:membreId |
| POST /tontines/{id}/mode | POST /assistant/cercles/:cercleId/mode |
| POST /propositions/{id}/decision | POST /assistant/propositions/:id/acceptation ou /refus |
| GET /registre/{tontine} | GET /cercles/:id/registre |
