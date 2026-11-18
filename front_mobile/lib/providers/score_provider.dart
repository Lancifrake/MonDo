import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/score_service.dart';
import 'api_client_provider.dart';

/// Provider pour le service de score
final scoreServiceProvider = Provider<ScoreService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScoreService(apiClient);
});

/// Provider pour récupérer le score d'un membre
final scoreMemberProvider =
    FutureProvider.family<ScoreMembre, String>((ref, membreId) async {
  final scoreService = ref.watch(scoreServiceProvider);
  return scoreService.getScore(membreId);
});

/// Provider pour récupérer mon score
final monScoreProvider = FutureProvider<ScoreMembre>((ref) async {
  final scoreService = ref.watch(scoreServiceProvider);
  return scoreService.getMonScore();
});

/// Provider pour rafraîchir le score
final scoreRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider augmenté qui dépend du provider de refresh
final monScoreRefreshableProvider = FutureProvider<ScoreMembre>((ref) async {
  ref.watch(scoreRefreshProvider); // Dépendre du refresh provider
  final scoreService = ref.watch(scoreServiceProvider);
  return scoreService.getMonScore();
});
