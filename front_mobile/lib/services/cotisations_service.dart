import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Cotisations : MonDo ne touche jamais l'argent. Le payeur paie hors de l'app
/// (Mobile Money, cash), DÉCLARE avec une référence, et le bénéficiaire CONFIRME.
class CotisationsService {
  final ApiClient _apiClient;

  CotisationsService(this._apiClient);

  List<Cotisation> _liste(dynamic json) => (json as List)
      .map((e) => Cotisation.fromJson(e as Map<String, dynamic>))
      .toList();

  /// GET /cotisations?cercleId=… (le serveur exige le cercle).
  Future<List<Cotisation>> getCotisationsCercle(String cercleId) => _apiClient.get<List<Cotisation>>(
        ApiConfig.pathCotisations,
        queryParameters: {'cercleId': cercleId},
        fromJson: _liste,
      );

  /// Mes cotisations dans tous mes cercles : ce que je dois et ce qu'on me doit.
  Future<List<Cotisation>> getMesCotisations({String? statut}) async {
    final cercles = await _apiClient.get<List<dynamic>>(
      ApiConfig.pathCercles,
      fromJson: (json) => json as List,
    );
    final toutes = <Cotisation>[];
    for (final c in cercles) {
      toutes.addAll(await getCotisationsCercle((c as Map)['id'] as String));
    }
    final filtrees = statut == null ? toutes : toutes.where((c) => c.statut == statut).toList();
    filtrees.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
    return filtrees;
  }

  /// Pas de route par cotisation : on la retrouve dans mes cotisations.
  Future<Cotisation> getCotisation(String cotisationId) async {
    final toutes = await getMesCotisations();
    return toutes.firstWhere(
      (c) => c.id == cotisationId,
      orElse: () => throw ApiException(message: 'Cotisation introuvable', statusCode: 404),
    );
  }

  /// POST /cotisations/:id/paiement : le payeur déclare, avec la référence de la transaction.
  Future<Cotisation> declarerPaiement({
    required String cotisationId,
    required String referenceTransaction,
    String? methode, // affichage seulement, le serveur ne le garde pas
    String? signature, // inutile : la requête elle-même est signée
  }) =>
      _apiClient.post<Cotisation>(
        '${ApiConfig.pathCotisations}/$cotisationId/paiement',
        data: {'referenceTransaction': referenceTransaction.trim()},
        fromJson: (json) => Cotisation.fromJson(json as Map<String, dynamic>),
      );

  /// POST /cotisations/:id/confirmation : le bénéficiaire confirme la réception. Aucun corps.
  Future<Cotisation> confirmerPaiement({
    required String cotisationId,
    String? proofImagePath, // le serveur ne reçoit pas de capture
    String? signature,
  }) =>
      _apiClient.post<Cotisation>(
        '${ApiConfig.pathCotisations}/$cotisationId/confirmation',
        data: const {},
        fromJson: (json) => Cotisation.fromJson(json as Map<String, dynamic>),
      );

  /// GET /cotisations/cercles/:id/etat : qui a payé, tour par tour.
  Future<EtatCotisations> getEtatCercle(String cercleId) => _apiClient.get<EtatCotisations>(
        '${ApiConfig.pathCotisations}/cercles/$cercleId/etat',
        fromJson: (json) => EtatCotisations.fromJson(json as Map<String, dynamic>),
      );

  /// GET /sommes-dues : frais, remises et remboursements.
  Future<List<SommeDue>> getSommesDues() => _apiClient.get<List<SommeDue>>(
        '/sommes-dues',
        fromJson: (json) => (json as List)
            .map((e) => SommeDue.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
