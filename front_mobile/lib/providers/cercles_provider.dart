import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/cercles_service.dart';
import 'api_client_provider.dart';

/// Provider pour le service des cercles
final cerclesServiceProvider = Provider<CerclesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CerclesService(apiClient);
});

/// Provider pour récupérer la liste des cercles de l'utilisateur
final mesCerclesProvider = FutureProvider<List<ResumeCercle>>((ref) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getMesCercles();
});

/// Provider pour récupérer le catalogue des cercles ouverts
final catalogueCerclesProvider =
    FutureProvider.family<List<Cercle>, CatalogueFilter>((ref, filter) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getCatalogue(
    montantMin: filter.montantMin,
    montantMax: filter.montantMax,
    frequence: filter.frequence,
    nombreMembreMax: filter.nombreMembreMax,
  );
});

/// Filtre pour le catalogue
class CatalogueFilter {
  final int? montantMin;
  final int? montantMax;
  final String? frequence;
  final int? nombreMembreMax;

  CatalogueFilter({
    this.montantMin,
    this.montantMax,
    this.frequence,
    this.nombreMembreMax,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogueFilter &&
          runtimeType == other.runtimeType &&
          montantMin == other.montantMin &&
          montantMax == other.montantMax &&
          frequence == other.frequence &&
          nombreMembreMax == other.nombreMembreMax;

  @override
  int get hashCode =>
      montantMin.hashCode ^
      montantMax.hashCode ^
      frequence.hashCode ^
      nombreMembreMax.hashCode;
}

/// Provider pour récupérer un cercle spécifique
final cercleProvider =
    FutureProvider.family<Cercle, String>((ref, cercleId) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getCercle(cercleId);
});

/// Provider pour les échanges d'un cercle
final echangesCercleProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, cercleId) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getEchanges(cercleId);
});

/// Provider pour l'état des cotisations d'un cercle
final etatCercleProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, cercleId) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getRegistre(cercleId);
});

/// Provider pour l'invalidation manuelle de la liste des cercles
final cerclesRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider augmenté qui dépend du provider de refresh
final mesCerclesRefreshableProvider =
    FutureProvider<List<ResumeCercle>>((ref) async {
  ref.watch(cerclesRefreshProvider); // Dépendre du refresh provider
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getMesCercles();
});
