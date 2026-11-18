import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_models.freezed.dart';
part 'api_models.g.dart';

// ============================================================================
// AUTHENTIFICATION & COMPTES
// ============================================================================

/// Réponse OTP du serveur
@freezed
class OtpResponse with _$OtpResponse {
  const factory OtpResponse({
    @JsonKey(name: 'codeExpirez') required String? codeExpirez,
    @JsonKey(name: 'codeEnvoyeLe') required String? codeEnvoyeLe,
  }) = _OtpResponse;

  factory OtpResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpResponseFromJson(json);
}

/// Réponse d'inscription
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

/// Profil du compte connecté
@freezed
class Compte with _$Compte {
  const factory Compte({
    required String id,
    required String numero,
    required String nom,
    required int niveau,
  }) = _Compte;

  factory Compte.fromJson(Map<String, dynamic> json) =>
      _$CompteFromJson(json);
}

// ============================================================================
// CERCLES (TONTINES)
// ============================================================================

/// Réglement d'un cercle
@freezed
class Reglement with _$Reglement {
  const factory Reglement({
    required int montant,
    required String frequence, // "hebdomadaire", "mensuelle", etc.
    required int nombreMembres,
    @JsonKey(name: 'penaliteRetard') int? penaliteRetard,
    @JsonKey(name: 'delaiGraceJours') int? delaiGraceJours,
    @JsonKey(name: 'ordreFixe') List<String>? ordreFixe,
    @JsonKey(name: 'scoreMinimum') int? scoreMinimum,
    bool? ouvert,
  }) = _Reglement;

  factory Reglement.fromJson(Map<String, dynamic> json) =>
      _$ReglementFromJson(json);
}

/// Cercle (Tontine)
@freezed
class Cercle with _$Cercle {
  const factory Cercle({
    required String id,
    @JsonKey(name: 'organisateurId') required String organisateurId,
    required Reglement reglement,
    @JsonKey(name: 'empreinteReglement') String? empreinteReglement,
    required List<String> membres,
    List<String>? partis,
    required String statut, // "en_attente", "complet", "termine"
    List<dynamic>? ordre,
    @JsonKey(name: 'termineLe') String? termineLe,
    String? nom,
    String? description,
  }) = _Cercle;

  factory Cercle.fromJson(Map<String, dynamic> json) =>
      _$CercleFromJson(json);
}

/// Résumé d'un cercle pour la liste
@freezed
class ResumeCercle with _$ResumeCercle {
  const factory ResumeCercle({
    required String id,
    required String nom,
    required String statut,
    required int nombreMembres,
    required int nombreMembresCible,
    @JsonKey(name: 'montantTotal') required int montantTotal,
    @JsonKey(name: 'montantTotal') String? frequence,
  }) = _ResumeCercle;

  factory ResumeCercle.fromJson(Map<String, dynamic> json) =>
      _$ResumeCercleFromJson(json);
}

// ============================================================================
// COTISATIONS
// ============================================================================

/// Cotisation
@freezed
class Cotisation with _$Cotisation {
  const factory Cotisation({
    required String id,
    @JsonKey(name: 'cercleId') required String cercleId,
    @JsonKey(name: 'payeur_id') required String payeurId,
    @JsonKey(name: 'beneficiaire_id') required String beneficiaireId,
    required int montant,
    @JsonKey(name: 'dateLimite') required String dateLimite,
    int? tour,
    required String statut, // "due", "declaree", "confirmee"
    @JsonKey(name: 'referenceTransaction') String? referenceTransaction,
    @JsonKey(name: 'declareeLe') String? declareeLe,
    @JsonKey(name: 'confirmee_le') String? confirmeeLe,
  }) = _Cotisation;

  /// Alias pour compatibilité avec les écrans
  String get beneficiaire => beneficiaireId;

  factory Cotisation.fromJson(Map<String, dynamic> json) =>
      _$CotisationFromJson(json);
}

/// État des cotisations par cercle
@freezed
class EtatCotisations with _$EtatCotisations {
  const factory EtatCotisations({
    required String cercleId,
    required List<EtatTour> tours,
  }) = _EtatCotisations;

  factory EtatCotisations.fromJson(Map<String, dynamic> json) =>
      _$EtatCotisationsFromJson(json);
}

/// État d'un tour
@freezed
class EtatTour with _$EtatTour {
  const factory EtatTour({
    required int numero,
    required List<EtatMembre> membres,
  }) = _EtatTour;

  factory EtatTour.fromJson(Map<String, dynamic> json) =>
      _$EtatTourFromJson(json);
}

/// État d'un membre pour une cotisation
@freezed
class EtatMembre with _$EtatMembre {
  const factory EtatMembre({
    required String id,
    required String statut, // "due", "declaree", "confirmee"
    required int montant,
  }) = _EtatMembre;

  factory EtatMembre.fromJson(Map<String, dynamic> json) =>
      _$EtatMembreFromJson(json);
}

// ============================================================================
// SCORE
// ============================================================================

/// Score de confiance d'un membre
@freezed
class ScoreMembre with _$ScoreMembre {
  const factory ScoreMembre({
    required int score,
    @JsonKey(name: 'premieresPlacesFermees') bool? premieresPlacesFermees,
    String? explication,
    List<EvenementScore>? historique,
  }) = _ScoreMembre;

  factory ScoreMembre.fromJson(Map<String, dynamic> json) =>
      _$ScoreMembreFromJson(json);
}

/// Événement du score
@freezed
class EvenementScore with _$EvenementScore {
  const factory EvenementScore({
    required String type,
    required int delta,
    required String cercleId,
    required String creeLe,
  }) = _EvenementScore;

  factory EvenementScore.fromJson(Map<String, dynamic> json) =>
      _$EvenementScoreFromJson(json);
}

// ============================================================================
// LITIGES
// ============================================================================

/// Litige
@freezed
class Litige with _$Litige {
  const factory Litige({
    required String id,
    @JsonKey(name: 'cotisationId') required String cotisationId,
    @JsonKey(name: 'cercleId') required String cercleId,
    @JsonKey(name: 'payeur_id') required String payeurId,
    @JsonKey(name: 'beneficiaire_id') required String beneficiaireId,
    required String motif,
    @JsonKey(name: 'ouvertPar') required String ouvertPar,
    @JsonKey(name: 'ouvertLe') required String ouvertLe,
    required String statut, // "ouvert", "tranche", "clos"
    String? decision,
    @JsonKey(name: 'motifDecision') String? motifDecision,
  }) = _Litige;

  factory Litige.fromJson(Map<String, dynamic> json) =>
      _$LitigeFromJson(json);
}

// ============================================================================
// NOTIFICATIONS
// ============================================================================

/// Notification
@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    @JsonKey(name: 'membre_id') required String membreId,
    required String titre,
    required String message,
    required String type, // "cotisation", "cercle", "litige", "score", "system"
    @JsonKey(name: 'date_creation') required String dateCreation,
    @JsonKey(name: 'lue_le') String? lueLe,
  }) = _Notification;

  /// Retourne true si la notification a été lue
  bool get lue => lueLe != null;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}

/// Réponse pour lister les notifications
@freezed
class NotificationsResponse with _$NotificationsResponse {
  const factory NotificationsResponse({
    required List<Notification> notifications,
    @JsonKey(name: 'nonLues') int? nonLues,
  }) = _NotificationsResponse;

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationsResponseFromJson(json);
}

// ============================================================================
// RÉPONSES GÉNÉRIQUES
// ============================================================================

/// Réponse de santé du serveur
@freezed
class HealthResponse with _$HealthResponse {
  const factory HealthResponse({
    required String statut,
  }) = _HealthResponse;

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);
}

/// Réponse d'erreur générique du serveur
@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String message,
    String? code,
    dynamic details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
