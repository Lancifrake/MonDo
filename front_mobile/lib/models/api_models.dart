import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_models.freezed.dart';
part 'api_models.g.dart';

// Les champs suivent EXACTEMENT les réponses du serveur (camelCase), relevées
// sur un vrai serveur le 18/11 : voir docs/conception/api.md.
// Les getters marqués « affichage » ne viennent pas du serveur : ils servent les écrans.

// ============================================================================
// COMPTES
// ============================================================================

/// POST /comptes/otp
@freezed
class OtpResponse with _$OtpResponse {
  const factory OtpResponse({String? expireLe}) = _OtpResponse;

  factory OtpResponse.fromJson(Map<String, dynamic> json) => _$OtpResponseFromJson(json);
}

/// POST /comptes
@freezed
class InscriptionResponse with _$InscriptionResponse {
  const factory InscriptionResponse({
    required String id,
    required String numero,
    required String nom,
    required int niveau,
  }) = _InscriptionResponse;

  factory InscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$InscriptionResponseFromJson(json);
}

/// GET /comptes/moi
@freezed
class Compte with _$Compte {
  const factory Compte({
    required String id,
    required String numero,
    required String nom,
    required int niveau,
  }) = _Compte;

  factory Compte.fromJson(Map<String, dynamic> json) => _$CompteFromJson(json);
}

// ============================================================================
// CERCLES (le serveur dit « cercle », l'écran dit « tontine »)
// ============================================================================

/// Frais d'une place (GET /cercles/bareme), recopiés tels quels dans le règlement.
@freezed
class FraisPlace with _$FraisPlace {
  const factory FraisPlace({
    required int place,
    required int frais,
    required int partMonDo,
    required int remiseParPlaceDeFin,
  }) = _FraisPlace;

  factory FraisPlace.fromJson(Map<String, dynamic> json) => _$FraisPlaceFromJson(json);
}

/// Règlement signé par l'organisateur : rien ne s'y modifie après la signature.
@freezed
class Reglement with _$Reglement {
  const factory Reglement({
    required int montant,
    required String frequence, // hebdomadaire, mensuelle, jours
    int? periodeJours,
    required int nombreMembres,
    required int penaliteRetard,
    required int delaiGraceJours,
    required bool ouvert,
    required String datePremierTour,
    required List<FraisPlace> bareme,
    List<int>? rappelsAvantEcheanceJours,
    int? scoreMinimum,
    List<String>? ordreFixe,
    bool? parrainageAccepte,
  }) = _Reglement;

  factory Reglement.fromJson(Map<String, dynamic> json) => _$ReglementFromJson(json);
}

/// Une place dans l'ordre de passage (membres du cercle seulement).
@freezed
class PlaceOrdre with _$PlaceOrdre {
  const factory PlaceOrdre({
    required String membreId,
    required int position,
    String? zone,
    int? placeSouhaitee,
  }) = _PlaceOrdre;

  factory PlaceOrdre.fromJson(Map<String, dynamic> json) => _$PlaceOrdreFromJson(json);
}

/// GET /cercles/:id, GET /cercles/catalogue, POST /cercles.
/// `membres` et `ordre` ne sont donnés qu'aux membres du cercle.
@freezed
class Cercle with _$Cercle {
  const factory Cercle({
    required String id,
    String? organisateurId,
    required Reglement reglement,
    String? empreinteReglement,
    @Default(<String>[]) List<String> membres,
    List<String>? partis,
    required String statut, // en_attente, complet, termine
    List<PlaceOrdre>? ordre,
    String? termineLe,
    int? placesRestantes,
    int? premierePlaceAutorisee,
    bool? scoreSuffisant,
    // Ordre fixé par l'organisateur (tontine privée) : vu par quelqu'un qui n'est pas encore membre.
    bool? ordreFixeParOrganisateur,
    int? placeFixee, // la place prévue pour moi, absente si je ne suis pas sur la liste
  }) = _Cercle;

  const Cercle._();

  /// Affichage : un cercle n'a pas de nom côté serveur.
  String get nom => 'Tontine de ${_milliers(reglement.montant)} FCFA';

  /// Affichage : rien côté serveur.
  String? get description => null;

  factory Cercle.fromJson(Map<String, dynamic> json) => _$CercleFromJson(json);
}

/// GET /cercles : mes cercles, avec ma place.
@freezed
class ResumeCercle with _$ResumeCercle {
  const factory ResumeCercle({
    required String id,
    @Default(false) bool organisateur,
    required Reglement reglement,
    required String statut,
    @Default(0) int nombreInscrits,
    int? maPlace,
  }) = _ResumeCercle;

  const ResumeCercle._();

  String get nom => 'Tontine de ${_milliers(reglement.montant)} FCFA';
  int get nombreMembres => nombreInscrits;
  int get nombreMembresCible => reglement.nombreMembres;
  int get montantTotal => reglement.montant;
  String get frequence => reglement.frequence;

  factory ResumeCercle.fromJson(Map<String, dynamic> json) => _$ResumeCercleFromJson(json);
}

// ============================================================================
// COTISATIONS
// ============================================================================

/// GET /cotisations?cercleId=…
@freezed
class Cotisation with _$Cotisation {
  const factory Cotisation({
    required String id,
    required String cercleId,
    required String payeurId,
    required String beneficiaireId,
    required int montant,
    required int tour,
    required String dateLimite,
    String? finGrace,
    required String statut, // due, declaree, confirmee
    String? referenceTransaction,
    String? declareeLe,
    String? confirmeeLe,
    @Default(false) bool enLitige,
    @Default(0) int penalite,
    @Default(0) int penaliteDue,
  }) = _Cotisation;

  const Cotisation._();

  String get beneficiaire => beneficiaireId;

  factory Cotisation.fromJson(Map<String, dynamic> json) => _$CotisationFromJson(json);
}

/// GET /cotisations/cercles/:id/etat
@freezed
class EtatCotisations with _$EtatCotisations {
  const factory EtatCotisations({
    required String cercleId,
    required List<EtatTour> tours,
  }) = _EtatCotisations;

  factory EtatCotisations.fromJson(Map<String, dynamic> json) => _$EtatCotisationsFromJson(json);
}

@freezed
class EtatTour with _$EtatTour {
  const factory EtatTour({
    required int numero,
    required String beneficiaireId,
    String? dateLimite,
    required List<EtatMembre> paiements,
  }) = _EtatTour;

  const EtatTour._();

  /// Affichage : les payeurs du tour.
  List<EtatMembre> get membres => paiements;

  factory EtatTour.fromJson(Map<String, dynamic> json) => _$EtatTourFromJson(json);
}

/// Un paiement dans un tour : qui doit, combien, où il en est.
@freezed
class EtatMembre with _$EtatMembre {
  const factory EtatMembre({
    required String payeurId,
    required int montant,
    required String statut,
    @Default(false) bool enRetard,
    @Default(false) bool enLitige,
    @Default(0) int penaliteDue,
  }) = _EtatMembre;

  const EtatMembre._();

  String get id => payeurId;

  factory EtatMembre.fromJson(Map<String, dynamic> json) => _$EtatMembreFromJson(json);
}

// ============================================================================
// SCORE
// ============================================================================

/// GET /score/:membreId
@freezed
class ScoreMembre with _$ScoreMembre {
  const factory ScoreMembre({
    required String membreId,
    required int score,
    @Default(0) int cyclesTermines,
    @Default(0) int defauts,
    @Default(false) bool premieresPlacesFermees,
    @Default(<String>[]) List<String> explication,
    @Default(<EvenementScore>[]) List<EvenementScore> historique,
  }) = _ScoreMembre;

  factory ScoreMembre.fromJson(Map<String, dynamic> json) => _$ScoreMembreFromJson(json);
}

@freezed
class EvenementScore with _$EvenementScore {
  const factory EvenementScore({
    required String date,
    required String type,
    String? cercleId,
    @Default(false) bool cerclePrive,
    required num points,
    required num scoreApres,
  }) = _EvenementScore;

  factory EvenementScore.fromJson(Map<String, dynamic> json) => _$EvenementScoreFromJson(json);
}

// ============================================================================
// LITIGES
// ============================================================================

/// GET /litiges/miens, GET /litiges/:id, POST /litiges
@freezed
class Litige with _$Litige {
  const factory Litige({
    required String id,
    required String cotisationId,
    required String cercleId,
    required String payeurId,
    required String beneficiaireId,
    required String ouvertPar, // payeur, beneficiaire, automatique
    required String motif,
    required String ouvertLe,
    required String statut, // ouvert, tranche, clos
    String? decision, // paiement_valide, paiement_refuse, confirme_par_beneficiaire
    String? motifDecision,
    String? tranchePar,
    String? trancheLe,
  }) = _Litige;

  factory Litige.fromJson(Map<String, dynamic> json) => _$LitigeFromJson(json);
}

// ============================================================================
// NOTIFICATIONS
// ============================================================================

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String texte,
    required String creeeLe,
    String? lueLe,
  }) = _Notification;

  const Notification._();

  bool get lue => lueLe != null;

  // Affichage : le serveur n'a qu'un texte.
  String get titre => 'MonDo';
  String get message => texte;
  String get type => 'system';
  String get dateCreation => creeeLe;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}

/// GET /notifications
@freezed
class NotificationsResponse with _$NotificationsResponse {
  const factory NotificationsResponse({
    required List<Notification> notifications,
    @Default(0) int nonLues,
  }) = _NotificationsResponse;

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationsResponseFromJson(json);
}

/// GET /sommes-dues : frais, remises, remboursements.
@freezed
class SommeDue with _$SommeDue {
  const factory SommeDue({
    required String id,
    required String cercleId,
    required String nature,
    String? debiteurId,
    String? creancierId,
    required int montant,
    int? tour,
    String? exigibleLe,
    String? dateLimite,
    required String statut,
  }) = _SommeDue;

  factory SommeDue.fromJson(Map<String, dynamic> json) => _$SommeDueFromJson(json);
}

String _milliers(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
