import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Service pour consulter et gérer le score de confiance
/// 
/// Le score détermine :
/// - L'accès aux premières places des cercles
/// - La confiance attribuée par le système
/// - L'accès à certaines fonctionnalités
class ScoreService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  ScoreService(this._apiClient);

  /// Récupère le score de confiance d'un membre
  /// 
  /// Le score est calculé basé sur :
  /// - Paiements à temps
  /// - Résolutions de litiges
  /// - Historique de participation
  Future<ScoreMembre> getScore(String membreId) async {
    try {
      _logger.i('Récupération score: $membreId');

      final response = await _apiClient.get<ScoreMembre>(
        '${ApiConfig.pathScore}/$membreId',
        fromJson: (json) =>
            ScoreMembre.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Score récupéré: ${response.score}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du score: $e');
      rethrow;
    }
  }

  /// Récupère le score de l'utilisateur courant
  Future<ScoreMembre> getMonScore() async {
    try {
      _logger.i('Récupération mon score');

      final response = await _apiClient.get<ScoreMembre>(
        '${ApiConfig.pathScore}/moi',
        fromJson: (json) =>
            ScoreMembre.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Mon score récupéré: ${response.score}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de mon score: $e');
      rethrow;
    }
  }
}
