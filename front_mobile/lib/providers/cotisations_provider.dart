import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/cotisations_service.dart';
import 'api_client_provider.dart';

/// Provider pour le service des cotisations
final cotisationsServiceProvider = Provider<CotisationsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CotisationsService(apiClient);
});

/// Provider pour récupérer toutes les cotisations de l'utilisateur
final mesCotisationsProvider = FutureProvider<List<Cotisation>>((ref) async {
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getMesCotisations();
});

/// Provider pour récupérer les cotisations filtrées par statut
final mesCotisationsFiltreesProvider =
    FutureProvider.family<List<Cotisation>, String>((ref, statut) async {
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getMesCotisations(statut: statut);
});

/// Provider pour récupérer une cotisation spécifique
final cotisationProvider =
    FutureProvider.family<Cotisation, String>((ref, cotisationId) async {
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getCotisation(cotisationId);
});

/// Provider pour l'état des cotisations d'un cercle
final etatCotisationsCercleProvider =
    FutureProvider.family<EtatCotisations, String>((ref, cercleId) async {
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getEtatCercle(cercleId);
});

/// Provider pour les cotisations d'un cercle
final cotisationsCercleProvider =
    FutureProvider.family<List<Cotisation>, String>((ref, cercleId) async {
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getCotisationsCercle(cercleId);
});

/// Provider pour rafraîchir les cotisations
final cotisationsRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider augmenté qui dépend du provider de refresh
final mesCotisationsRefreshableProvider =
    FutureProvider<List<Cotisation>>((ref) async {
  ref.watch(cotisationsRefreshProvider); // Dépendre du refresh provider
  final cotisationsService = ref.watch(cotisationsServiceProvider);
  return cotisationsService.getMesCotisations();
});
