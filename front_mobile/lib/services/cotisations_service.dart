import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Service pour gérer les cotisations
/// 
/// Gère :
/// - Récupération des cotisations dues
/// - Déclaration de paiement
/// - Confirmation de paiement
/// - État des cotisations par cercle
class CotisationsService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  CotisationsService(this._apiClient);

  /// Récupère toutes les cotisations de l'utilisateur
  Future<List<Cotisation>> getMesCotisations({
    String? statut, // "due", "declaree", "confirmee"
  }) async {
    try {
      _logger.i('Récupération des cotisations');

      final queryParams = <String, dynamic>{
        if (statut != null) 'statut': statut,
      };

      final response = await _apiClient.get<List<Cotisation>>(
        ApiConfig.pathCotisations,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) =>
                  Cotisation.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} cotisations récupérées');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des cotisations: $e');
      rethrow;
    }
  }

  /// Récupère les détails d'une cotisation
  Future<Cotisation> getCotisation(String cotisationId) async {
    try {
      _logger.i('Récupération cotisation: $cotisationId');

      final response = await _apiClient.get<Cotisation>(
        '${ApiConfig.pathCotisations}/$cotisationId',
        fromJson: (json) =>
            Cotisation.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Cotisation récupérée');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de la cotisation: $e');
      rethrow;
    }
  }

  /// Déclare un paiement pour une cotisation
  /// 
  /// Le paiement peut être fait via :
  /// - Mobile Money (Orange Money, MTN Money, etc.)
  /// - Virement bancaire
  /// - Autre méthode définie par le serveur
  Future<Cotisation> declarerPaiement({
    required String cotisationId,
    required String methode, // "mobile_money", "virement", etc.
    required String referenceTransaction,
    required String signature, // Signature de la déclaration
  }) async {
    try {
      _logger.i('Déclaration paiement: $cotisationId');

      final request = {
        'methode': methode,
        'referenceTransaction': referenceTransaction,
        'signature': signature,
      };

      final response = await _apiClient.post<Cotisation>(
        '${ApiConfig.pathCotisations}/$cotisationId/paiement',
        data: request,
        fromJson: (json) =>
            Cotisation.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Paiement déclaré');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la déclaration du paiement: $e');
      rethrow;
    }
  }

  /// Confirme un paiement précédemment déclaré
  /// 
  /// Cette confirmation valide le paiement et ferme la transaction
  /// L'image de preuve est convertie en base64 pour l'envoi
  Future<Cotisation> confirmerPaiement({
    required String cotisationId,
    required String proofImagePath, // Chemin local de l'image de preuve
    required String signature, // Signature de la confirmation
  }) async {
    try {
      _logger.i('Confirmation paiement: $cotisationId');

      // Lire l'image et la convertir en base64
      // Note: En production, vérifier que le chemin est valide
      final imageFile = File(proofImagePath);
      if (!await imageFile.exists()) {
        throw ApiException(
          message: 'Fichier image non trouvé: $proofImagePath',
        );
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final request = {
        'preuve': base64Image,
        'signature': signature,
      };

      final response = await _apiClient.post<Cotisation>(
        '${ApiConfig.pathCotisations}/$cotisationId/confirmation',
        data: request,
        fromJson: (json) =>
            Cotisation.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Paiement confirmé');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la confirmation du paiement: $e');
      rethrow;
    }
  }

  /// Récupère l'état des cotisations d'un cercle
  /// 
  /// Montre l'état de toutes les cotisations de chaque tour du cercle
  Future<EtatCotisations> getEtatCercle(String cercleId) async {
    try {
      _logger.i('Récupération état cotisations: $cercleId');

      final response = await _apiClient.get<EtatCotisations>(
        '${ApiConfig.pathCotisations}/cercles/$cercleId/etat',
        fromJson: (json) =>
            EtatCotisations.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('État récupéré pour ${response.tours.length} tours');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de l\'état: $e');
      rethrow;
    }
  }

  /// Récupère les cotisations d'un cercle spécifique
  Future<List<Cotisation>> getCotisationsCercle(String cercleId) async {
    try {
      _logger.i('Récupération cotisations cercle: $cercleId');

      final response = await _apiClient.get<List<Cotisation>>(
        '${ApiConfig.pathCotisations}/cercles/$cercleId',
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) =>
                  Cotisation.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} cotisations du cercle récupérées');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des cotisations du cercle: $e');
      rethrow;
    }
  }
}
