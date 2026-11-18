import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/notifications_service.dart';
import 'api_client_provider.dart';

/// Provider pour le service des notifications
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsService(apiClient);
});

/// Provider pour récupérer toutes les notifications
final notificationsProvider = FutureProvider<List<Notification>>((ref) async {
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.getNotifications();
});

/// Provider pour récupérer uniquement les notifications non lues
final notificationsNonLuesProvider =
    FutureProvider<List<Notification>>((ref) async {
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.getNotificationsNonLues();
});

/// Provider pour compter les notifications non lues
final comptNotificationsNonLuesProvider =
    FutureProvider<int>((ref) async {
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.comptorNotificationsNonLues();
});

/// Provider pour rafraîchir les notifications
final notificationsRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider augmenté qui dépend du provider de refresh
final notificationsRefreshableProvider =
    FutureProvider<List<Notification>>((ref) async {
  ref.watch(notificationsRefreshProvider); // Dépendre du refresh provider
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.getNotifications();
});

/// Provider augmenté pour les notifications non lues avec refresh
final notificationsNonLuesRefreshableProvider =
    FutureProvider<List<Notification>>((ref) async {
  ref.watch(notificationsRefreshProvider); // Dépendre du refresh provider
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.getNotificationsNonLues();
});
