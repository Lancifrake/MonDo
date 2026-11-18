import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Score de confiance (GET /score/:membreId).
class ScoreService {
  final ApiClient _apiClient;

  ScoreService(this._apiClient);

  Future<ScoreMembre> getScore(String membreId) => _apiClient.get<ScoreMembre>(
        '${ApiConfig.pathScore}/$membreId',
        fromJson: (json) => ScoreMembre.fromJson(json as Map<String, dynamic>),
      );

  /// Il n'y a pas de route « /score/moi » : on passe son propre identifiant.
  Future<ScoreMembre> getMonScore() {
    final moi = _apiClient.membreId;
    if (moi == null) throw ApiException(message: 'Non connecté');
    return getScore(moi);
  }
}
