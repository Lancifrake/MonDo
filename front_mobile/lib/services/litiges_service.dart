import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Service pour gérer les litiges
/// 
/// Gère :
/// - Ouverture d'un litige
/// - Récupération des litiges
/// - Soumission d'une décision
/// - Consultation du registre des litiges
class LitigesService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  LitigesService(this._apiClient);

  /// Ouvre un nouveau litige
  /// 
  /// Utilisé quand un paiement n'a pas été confirmé et qu'il y a désaccord
  Future<Litige> ouvrirLitige({
    required String cotisationId,
    required String motif,
    required String signature, // Signature de l'ouverture
  }) async {
    try {
      _logger.i('Ouverture litige pour cotisation: $cotisationId');

      final request = {
        'motif': motif,
        'signature': signature,
      };

      final response = await _apiClient.post<Litige>(
        ApiConfig.pathLitiges,
        data: request,
        fromJson: (json) => Litige.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Litige ouvert: ${response.id}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de l\'ouverture du litige: $e');
      rethrow;
    }
  }

  /// Récupère les litiges de l'utilisateur
  Future<List<Litige>> getMesLitiges({
    String? statut, // "ouvert", "tranche", "clos"
  }) async {
    try {
      _logger.i('Récupération des litiges');

      final queryParams = <String, dynamic>{
        if (statut != null) 'statut': statut,
      };

      final response = await _apiClient.get<List<Litige>>(
        '${ApiConfig.pathLitiges}/miens',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) => Litige.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} litiges récupérés');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des litiges: $e');
      rethrow;
    }
  }

  /// Récupère les détails d'un litige
  Future<Litige> getLitige(String litigeId) async {
    try {
      _logger.i('Récupération litige: $litigeId');

      final response = await _apiClient.get<Litige>(
        '${ApiConfig.pathLitiges}/$litigeId',
        fromJson: (json) => Litige.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Litige récupéré');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du litige: $e');
      rethrow;
    }
  }

  /// Soumet une décision pour un litige (en tant qu'arbitre)
  /// 
  /// Utilisé par un arbitre pour résoudre un litige
  /// decision peut être "approuve", "rejette", "partiel"
  Future<Litige> soumettreDecision({
    required String litigeId,
    required String decision,
    required String motif,
    required String signature, // Signature de la décision
  }) async {
    try {
      _logger.i('Soumission décision litige: $litigeId');

      final request = {
        'decision': decision,
        'motif': motif,
        'signature': signature,
      };

      final response = await _apiClient.post<Litige>(
        '${ApiConfig.pathLitiges}/$litigeId/decision',
        data: request,
        fromJson: (json) => Litige.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Décision soumise');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la soumission de la décision: $e');
      rethrow;
    }
  }

  /// Récupère les litiges qui demandent une décision (pour un arbitre)
  Future<List<Litige>> getLitigesEnAttente() async {
    try {
      _logger.i('Récupération litiges en attente de décision');

      final response = await _apiClient.get<List<Litige>>(
        '${ApiConfig.pathLitiges}/en-attente',
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) => Litige.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} litiges en attente trouvés');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des litiges en attente: $e');
      rethrow;
    }
  }
}
