import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Litiges sur un paiement déclaré et non confirmé. Seul un administrateur tranche :
/// le membre ouvre et consulte, il ne décide pas.
class LitigesService {
  final ApiClient _apiClient;

  LitigesService(this._apiClient);

  /// POST /litiges : payeur (après 48 h sans confirmation) ou bénéficiaire.
  Future<Litige> ouvrirLitige({required String cotisationId, required String motif}) =>
      _apiClient.post<Litige>(
        ApiConfig.pathLitiges,
        data: {'cotisationId': cotisationId, 'motif': motif.trim()},
        fromJson: (json) => Litige.fromJson(json as Map<String, dynamic>),
      );

  /// GET /litiges/miens
  Future<List<Litige>> getMesLitiges({String? statut}) async {
    final liste = await _apiClient.get<List<Litige>>(
      '${ApiConfig.pathLitiges}/miens',
      fromJson: (json) => (json as List)
          .map((e) => Litige.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return statut == null ? liste : liste.where((l) => l.statut == statut).toList();
  }

  /// GET /litiges/:id
  Future<Litige> getLitige(String litigeId) => _apiClient.get<Litige>(
        '${ApiConfig.pathLitiges}/$litigeId',
        fromJson: (json) => Litige.fromJson(json as Map<String, dynamic>),
      );
}
