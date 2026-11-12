# Diagramme de classes : spécification pour Visual Paradigm

Date : 04/11/2026, mis à jour le 11/11/2026 (décisions de David du 11/11, voir la section 12). Modèle du domaine validé par David le 03/11 (score comme historique d'événements, Administrateur classe séparée, classes V2 incluses en gris), complété par ce que le code contient (`src/serveur`). Le diagramme se dessine dans Visual Paradigm à partir de ce texte ; une fois dessiné, le fichier VP fait foi et ce texte sert de référence.

Version PlantUML à importer dans Visual Paradigm (11/11, à jour) : [`classes/mondo-diagramme-de-classes.puml`](classes/mondo-diagramme-de-classes.puml). Dans Visual Paradigm Online, coller le texte dans l'import PlantUML (langage PlantUML) puis OK : classes, paquetages, énumérations et relations sont créés. C'est une aide tirée de ce texte, pas une source.

Version draw.io (04/11, périmée) : [`classes/mondo-diagramme-de-classes.drawio`](classes/mondo-diagramme-de-classes.drawio). Elle ne contient ni les tours, ni les litiges, ni la place souhaitée ; garder la version PlantUML.

## Comment le dessiner
- **Un paquetage par module** du serveur (décision 02) : Comptes et identité, Cercles et règlement, Cotisations, Score et ordre de passage, Planificateur, Dossier de preuve, Litiges, Assistant, Registre.
- **Classes V2** (phase 2) : remplissage gris, et stéréotype `«V2»`.
- **Classes calculées** (jamais stockées) : stéréotype `«calculé»`.
- **Énumérations** : stéréotype `«enumeration»`, regroupées dans un paquetage Types.
- Composition (losange plein) quand la partie n'existe pas sans le tout ; association simple sinon. Multiplicités aux deux bouts.
- Les associations entre paquetages se font **par identifiant** dans le code (aucune clé étrangère entre schémas) : dans le diagramme, ce sont des associations normales, la règle est notée dans une note du diagramme.

## 1. Comptes et identité
| Classe | Attributs | Remarques |
|---|---|---|
| **Utilisateur** | id : UUID ; numero : String ; nom : String ; niveauIdentite : NiveauIdentite ; creeLe : DateTime | code : `Compte` ; opération `passerAuNiveau2()` |
| **CleSignature** | clePublique : JWK (ECDSA P-256) ; creeeLe : DateTime ; revoqueeLe : DateTime [0..1] | la clé privée n'est jamais sur le serveur ; une seule clé active |
| **CodeOtp** | numero : String ; empreinteCode : String ; expireLe : DateTime ; essais : Integer ; consomme : Boolean ; envois : Integer ; fenetreDebut : DateTime | 5 min, 5 essais, usage unique, 5 codes par numéro sur 24 h (06/11) |
| **VerificationIdentite** | id : UUID ; typePiece : String ; consentementLe : DateTime ; versionConsentement : String ; deposeeLe : DateTime ; statut : StatutVerification ; motifDecision : String [0..1] ; decideeLe : DateTime [0..1] ; conserverJusquAu : DateTime [0..1] | vérification interne (11/11) : recto, verso et selfie déposés par le membre, décision d'un Administrateur avec motif, inscrite au registre |
| **PieceIdentite** | nature : NaturePiece ; cleStockage : String ; empreinte : String ; supprimeeLe : DateTime [0..1] | image chiffrée dans le stockage d'objets, jamais en base ; selfie supprimé juste après la décision ; carte gardée 5 ans après le dernier cercle du membre (durée provisoire) |
| **AccesPiece** | consulteeLe : DateTime | journal : quel Administrateur a ouvert quelle pièce |
| **ContactConfiance** | nom : String ; numero : String ; demandeLe : DateTime ; consentementLe : DateTime [0..1] | exigé au niveau 2, facultatif au niveau 1, accord du contact par SMS, aucun engagement financier |
| **DemandeRecuperation** | id : UUID ; nouvelleClePublique : JWK ; demandeeLe : DateTime ; finDelaiLe : DateTime ; avecContact : Boolean ; statut : StatutRecuperation | 48 h avec contact de confiance ; sans contact, 72 h plus carte d'identité et selfie (11/11) |
| **BlocageCompte** | motif : MotifBlocage ; bloqueLe : DateTime ; finLe : DateTime [0..1] ; leveLe : DateTime [0..1] | règle du 03/11 : dates limites et délai de grâce suspendus, autres membres prévenus |
| **Administrateur** | id : UUID ; nom : String | ne déplace jamais d'argent, ne modifie jamais un score |

Relations :
- Utilisateur 1 ◆── 1..* CleSignature (composition)
- Utilisateur 1 ── 0..* VerificationIdentite ; VerificationIdentite 1 ◆── 0..3 PieceIdentite ; PieceIdentite 1 ◆── 0..* AccesPiece
- Administrateur 0..1 ── 0..* VerificationIdentite (« décide ») ; Administrateur 1 ── 0..* AccesPiece
- Utilisateur 1 ── 0..* BlocageCompte
- Utilisateur 1 ── 0..1 ContactConfiance
- Utilisateur 1 ── 0..* DemandeRecuperation
- Administrateur 0..1 ── 0..* DemandeRecuperation (« tranche » une récupération contestée)

## 2. Cercles et règlement
| Classe | Attributs | Remarques |
|---|---|---|
| **Cercle** | id : UUID ; statut : StatutCercle ; creeLe : DateTime ; termineLe : DateTime [0..1] | |
| **Reglement** | montant : Integer ; frequence : Frequence ; periodeJours : Integer {1..60} [0..1] ; nombreMembres : Integer {3..50} ; penaliteRetard : Integer ; delaiGraceJours : Integer {0..30, plus court que la période} ; ouvert : Boolean ; rappelsAvantEcheanceJours : Integer [0..5] ; datePremierTour : DateTime ; ordreFixe : UUID [0..50] ; empreinte : String | signé par l'organisateur, figé ; ordreFixe seulement en cercle privé (11/11) |
| **LigneBareme** | place : Integer ; frais : Integer ; partMonDo : Integer ; remiseParPlaceDeFin : Integer | frais du modèle A, chiffrés dans le règlement signé (11/11) |
| **Adhesion** | rang : Integer ; placeSouhaitee : Integer ; adhereLe : DateTime ; partiLe : DateTime [0..1] | rang 1 = organisateur ; place signée dans l'engagement (08/11) |
| **DocumentSigne** | type : TypeDocument ; message : String ; signature : String ; empreinte : String | message canonique, vérifiable avec la clé publique |
| **PlaceOrdre** | position : Integer ; zone : Zone ; placeSouhaitee : Integer | attribuée quand le cercle est complet (score prioritaire, plus proche plutôt après) |
| **EchangePlace** | id : UUID ; proposeLe : DateTime ; expireLe : DateTime ; signatureDemandeur : String ; signatureCedant : String [0..1] ; statut : StatutEchange | gratuit au prototype, signé par les deux, expire à 48 h, jamais plus tôt que le score, suspendu pendant une récupération (11/11) |

Relations :
- Cercle 1 ◆── 1 Reglement ; Reglement 1 ◆── 0..* LigneBareme
- Cercle 1 ◆── 1..50 Adhesion
- Utilisateur 1 ── 0..* Adhesion
- Cercle 0..* ── 1 Utilisateur, rôle « organisateur »
- Adhesion 1 ◆── 1..* DocumentSigne
- Cercle 1 ◆── 0..* PlaceOrdre ; PlaceOrdre 0..* ── 1 Utilisateur
- EchangePlace 0..* ── 1 Cercle ; EchangePlace ── 1 Utilisateur rôle « demandeur » ; EchangePlace ── 1 Utilisateur rôle « cédant »

## 3. Cotisations
| Classe | Attributs | Remarques |
|---|---|---|
| **Tour** | numero : Integer ; dateLimite : DateTime | généré quand le cercle est complet (05/11) |
| **Cotisation** | id : UUID ; montant : Integer ; dateLimite : DateTime ; finGrace : DateTime ; referenceTransaction : String [0..1] ; declareeLe : DateTime [0..1] ; enLitige : Boolean ; penalite : Integer ; penaliteDueLe : DateTime [0..1] ; statut : StatutCotisation | confirmée par le seul bénéficiaire, le silence ne vaut pas confirmation ; déclaration gelée tant que enLitige ; pénalité du règlement due au bénéficiaire à la fin de grâce, une fois (11/11) |
| **SommeDue** | id : UUID ; nature : NatureSomme ; montant : Integer ; exigibleLe : DateTime ; dateLimite : DateTime ; referenceTransaction : String [0..1] ; declareeLe : DateTime [0..1] ; statut : StatutSomme | frais dus à MonDo, remise due à une place de fin, remboursement après un départ : suivie comme une cotisation (11/11) |
| **Depart** | partiLe : DateTime | avant d'avoir reçu la cagnotte seulement (11/11) |

Relations :
- Cercle 1 ◆── 1..* Tour ; Tour 0..* ── 1 Utilisateur rôle « bénéficiaire »
- Tour 1 ◆── 0..* Cotisation ; Cotisation 0..* ── 1 Utilisateur rôle « payeur »
- Cercle 1 ── 0..* SommeDue ; SommeDue 0..* ── 1 Utilisateur rôle « débiteur » ; SommeDue 0..* ── 0..1 Utilisateur rôle « créancier » (aucun : la somme revient à MonDo)
- Cercle 1 ── 0..* Depart ; Depart 0..* ── 1 Utilisateur

## 4. Score et ordre de passage
| Classe | Attributs | Remarques |
|---|---|---|
| **EvenementScore** | type : TypeEvenementScore ; date : DateTime ; cerclePrive : Boolean | jamais modifié ni supprimé ; en cercle privé les gains comptent moitié moins (11/11) |
| **Score** `«calculé»` | valeur : Integer {0..100} ; cyclesTermines : Integer ; defauts : Integer | rejeu des événements, plancher 0 et plafond 100 à chaque pas |

Relations :
- Utilisateur 1 ── 0..* EvenementScore ; EvenementScore 0..* ── 1 Cercle
- Utilisateur 1 ── 1 Score (dépendance pointillée « calculé à partir de » vers EvenementScore)

## 5. Planificateur
| Classe | Attributs | Remarques |
|---|---|---|
| **TachePlanifiee** | idUnique : String ; type : TypeTache ; traiteeLe : DateTime | rejouable : un identifiant ne se traite qu'une fois |

Relation : TachePlanifiee 0..* ── 0..1 Cotisation (échéance, retard).

## 6. Dossier de preuve
| Classe | Attributs | Remarques |
|---|---|---|
| **MiseEnDemeure** | id : UUID ; tour : Integer ; emiseLe : DateTime ; montantCotisations : Integer ; montantPenalites : Integer ; montantTotal : Integer ; envoi : EtatEnvoi ; envoyeeLe : DateTime [0..1] ; empreinte : String | montants du règlement signé ; une par défaut constaté |
| **DossierDePreuve** `«calculé»` | genereLe : DateTime ; empreinte : String | généré à l'export, seulement par les membres lésés |

Relations :
- MiseEnDemeure 0..* ── 1 Utilisateur rôle « débiteur » ; MiseEnDemeure 0..* ── 1 Cercle ; MiseEnDemeure 0..* ── 1..* Cotisation
- DossierDePreuve ── 1 Utilisateur rôle « débiteur », 1..* MiseEnDemeure, 1 Reglement, 1..* DocumentSigne, 0..* Cotisation (relevé)

## 7. Litiges
Module à part dans le code (`src/modules/litiges`) depuis le 05/11.

| Classe | Attributs | Remarques |
|---|---|---|
| **Litige** | id : UUID ; ouvertPar : OrigineLitige ; motif : String ; ouvertLe : DateTime ; statut : StatutLitige ; decision : DecisionLitige [0..1] ; motifDecision : String [0..1] ; trancheLe : DateTime [0..1] | sur un paiement déclaré non confirmé ; un seul ouvert par cotisation (05/11) |

Relations :
- Litige 0..* ── 1 Cotisation ; Litige 0..* ── 0..1 Utilisateur rôle « ouvert par » (aucun si ouverture automatique) ; Litige 0..* ── 0..1 Administrateur rôle « tranche »

## 8. Assistant (décision 04)
| Classe | Attributs | Remarques |
|---|---|---|
| **ReglageAssistant** | mode : ModeAssistant | manuel par défaut |
| **ActionAssistant** | id : UUID ; type : TypeAction ; issue : IssueAction ; creeeLe : DateTime ; trancheeLe : DateTime [0..1] | journal tracé |
| **Agent** `«interface»` | nom : NomAgent ; `recevoir(message) : Message[]` | |
| **Surveillance**, **Relance**, **Preuve**, **Coordinateur** | | réalisent Agent ; Coordinateur applique le mode |
| **Message** | de : NomAgent ; vers : NomAgent ; corps | |

Relations :
- Cercle 1 ── 0..1 ReglageAssistant ; Cercle 1 ── 0..* ActionAssistant ; ActionAssistant 0..* ── 1 Utilisateur rôle « cible »
- Surveillance, Relance, Preuve, Coordinateur ··▷ Agent (réalisation)
- Coordinateur 1 ── 0..* ActionAssistant (produit)
- ActionAssistant de type mise_en_demeure ── 0..1 MiseEnDemeure (envoie)

## 9. Registre
| Classe | Attributs | Remarques |
|---|---|---|
| **EmpreinteRegistre** | id : Integer ; empreinte : String | SHA-256, aucune donnée personnelle |
| **LotRegistre** | id : Integer ; racine : String ; referenceInscription : String [0..1] ; fermeLe : DateTime | une racine par lot sur la chaîne ; sans référence = à reprendre |

Relation : LotRegistre 0..1 ◆── 1..* EmpreinteRegistre (une empreinte en attente n'a pas encore de lot).

## 10. Classes V2 (en gris)
| Classe | Attributs | Remarques |
|---|---|---|
| **FondsDeGarantie** `«V2»` | id : UUID ; plafond : Integer | tenu par un partenaire agréé, jamais par MonDo |
| **RetenueSurPassage** `«V2»` | taux : Decimal ; montant : Integer | prélevée au passage, versée au fonds |

Relations : Cercle 1 ── 0..1 FondsDeGarantie ; Tour 1 ── 0..1 RetenueSurPassage ; RetenueSurPassage 0..* ── 1 FondsDeGarantie.

## 11. Énumérations
| Énumération | Valeurs |
|---|---|
| NiveauIdentite | 1, 2 |
| Frequence | hebdomadaire, mensuelle, jours (tous les periodeJours jours, au choix du cercle, 05/11) |
| StatutCercle | en_attente, complet, termine (fin de grâce du dernier tour, 05/11) |
| Zone | debut, milieu, fin |
| TypeDocument | reglement, engagement |
| StatutEchange | propose, signe, refuse, expire, suspendu |
| StatutCotisation | due, declaree, confirmee, annulee (départ d'un membre) |
| NatureSomme | frais_mondo, remise, remboursement_depart |
| StatutSomme | due, declaree, confirmee, annulee |
| StatutVerification | en_attente, validee, refusee |
| NaturePiece | recto, verso, selfie |
| MotifBlocage | essais_rates (levé par le temps), opposition (levé par l'Administrateur) |
| TypeEvenementScore | cotisation_a_temps (+4), cotisation_en_retard (−1), defaut (−30), cycle_termine (+10), depart (−15) |
| TypeTache | echeance, retard, defaut, relance_confirmation (24 h puis 48 h), litige, cycle, cercle_termine |
| EtatEnvoi | a_envoyer, envoyee |
| StatutLitige | ouvert, tranche, clos (le bénéficiaire a fini par confirmer) |
| OrigineLitige | payeur (après 48 h), beneficiaire (« rien reçu »), automatique (fin de grâce) |
| DecisionLitige | paiement_valide, paiement_refuse, confirme_par_beneficiaire |
| StatutRecuperation | en_attente, opposee, acceptee, refusee, expiree |
| ModeAssistant | autonome, manuel |
| TypeAction | rappel, rappel_retard, mise_en_demeure |
| IssueAction | executee, en_attente, acceptee, refusee, hors_reglement |
| NomAgent | surveillance, relance, preuve, coordinateur |

## 12. Décisions du 11/11 reportées dans ce modèle
- Vérification d'identité interne : VerificationIdentite, PieceIdentite (image chiffrée hors base), AccesPiece.
- Contact de confiance avec accord par SMS ; récupération en 48 h avec contact, 72 h avec carte et selfie sans ; BlocageCompte.
- Règlement : ordreFixe (cercle privé) et barème des frais du modèle A (LigneBareme).
- SommeDue : frais dus à MonDo, remises aux places de fin, remboursements après un départ. MonDo ne détient jamais les fonds : ce sont des paiements suivis, faits hors de MonDo.
- Cotisation : pénalité due au bénéficiaire à la fin de grâce ; statut annulee après un départ. Depart.
- EvenementScore : cerclePrive, moitié des gains.
- EchangePlace : gratuit, plus d'attribut frais.
- Les stéréotypes «calculé» restent sur Score et DossierDePreuve.

## Écarts entre le modèle et le code (11/11)
| Dans le modèle | Dans le code |
|---|---|
| CleSignature, classe à part | attribut `clePublique` du compte ; une seule clé, pas encore de rotation |
| DocumentSigne | la signature est stockée sur l'adhésion |
| VerificationIdentite, PieceIdentite, AccesPiece, ContactConfiance, DemandeRecuperation, BlocageCompte | pas encore codés |
| LigneBareme, ordreFixe, SommeDue, Depart, EchangePlace, pénalité de la cotisation, cerclePrive | pas encore codés |
| Administrateur | prototype : comptes membres listés dans `MONDO_ADMINISTRATEURS`, pas de classe à part |
| Reconnaissance de dette | volontairement absente : créancier et montant non tranchés (recours-legaux.md, section 5) |

Ces écarts sont la liste des prochains travaux du serveur, pas des erreurs du modèle. La version PlantUML (`classes/mondo-diagramme-de-classes.puml`) date d'avant le 11/11 : elle ne contient pas encore les classes de la section 12.
