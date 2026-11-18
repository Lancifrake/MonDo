import 'package:flutter/foundation.dart' hide Notification;
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Boîte de notifications (GET /notifications).
class NotificationsService {
  final ApiClient _apiClient;

  NotificationsService(this._apiClient);

  Future<NotificationsResponse> getBoite() => _apiClient.get<NotificationsResponse>(
        ApiConfig.pathNotifications,
        fromJson: (json) => NotificationsResponse.fromJson(json as Map<String, dynamic>),
      );

  Future<List<Notification>> getNotifications({bool? nonLues}) async {
    final liste = (await getBoite()).notifications;
    return nonLues == true ? liste.where((n) => !n.lue).toList() : liste;
  }

  Future<List<Notification>> getNotificationsNonLues() => getNotifications(nonLues: true);

  Future<int> comptorNotificationsNonLues() async => (await getBoite()).nonLues;

  /// POST /notifications/:id/lue
  Future<void> marquerCommeLue(String notificationId) => _apiClient.post<dynamic>(
        '${ApiConfig.pathNotifications}/$notificationId/lue',
        data: const {},
        fromJson: (json) => json,
      );

  /// POST /notifications/lues
  Future<void> marquerToutesCommeLues() => _apiClient.post<dynamic>(
        '${ApiConfig.pathNotifications}/lues',
        data: const {},
        fromJson: (json) => json,
      );

  @visibleForTesting
  ApiClient get client => _apiClient;
}
