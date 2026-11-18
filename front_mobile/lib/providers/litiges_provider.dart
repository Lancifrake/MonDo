import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/litiges_service.dart';
import 'api_client_provider.dart';

/// Provider pour le service des litiges
final litigesServiceProvider = Provider<LitigesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LitigesService(apiClient);
});

/// Provider pour récupérer mes litiges
final mesLitigesProvider = FutureProvider<List<Litige>>((ref) async {
  final litigesService = ref.watch(litigesServiceProvider);
  return litigesService.getMesLitiges();
});

/// Provider pour récupérer mes litiges filtrés par statut
final mesLitigesFiltreesProvider =
    FutureProvider.family<List<Litige>, String>((ref, statut) async {
  final litigesService = ref.watch(litigesServiceProvider);
  return litigesService.getMesLitiges(statut: statut);
});

/// Provider pour récupérer un litige spécifique
final litigeProvider =
    FutureProvider.family<Litige, String>((ref, litigeId) async {
  final litigesService = ref.watch(litigesServiceProvider);
  return litigesService.getLitige(litigeId);
});


/// Provider pour rafraîchir les litiges
final litigesRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider augmenté qui dépend du provider de refresh
final mesLitigesRefreshableProvider =
    FutureProvider<List<Litige>>((ref) async {
  ref.watch(litigesRefreshProvider); // Dépendre du refresh provider
  final litigesService = ref.watch(litigesServiceProvider);
  return litigesService.getMesLitiges();
});
