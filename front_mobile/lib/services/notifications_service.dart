import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';

/// Service pour gérer les notifications
/// 
/// Gère :
/// - Récupération de la liste des notifications
/// - Marquer une notification comme lue
/// - Compter les notifications non lues
class NotificationsService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  NotificationsService(this._apiClient);

  /// Récupère les notifications de l'utilisateur
  Future<List<Notification>> getNotifications({
    int? limit,
    int? offset,
    bool? nonLues, // Filtrer par statut (lues/non-lues)
  }) async {
    try {
      _logger.i('Récupération notifications');

      final queryParams = <String, dynamic>{
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (nonLues != null) 'nonLues': nonLues,
      };

      final response = await _apiClient.get<List<Notification>>(
        ApiConfig.pathNotifications,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          final list = json as List;
          return list
              .map((item) =>
                  Notification.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      _logger.i('${response.length} notifications récupérées');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des notifications: $e');
      rethrow;
    }
  }

  /// Récupère uniquement les notifications non lues
  Future<List<Notification>> getNotificationsNonLues() async {
    try {
      return await getNotifications(nonLues: true);
    } catch (e) {
      _logger.e('Erreur lors de la récupération des notifications non lues: $e');
      rethrow;
    }
  }

  /// Marque une notification comme lue
  Future<Notification> marquerCommeLue(String notificationId) async {
    try {
      _logger.i('Marquage notification comme lue: $notificationId');

      final response = await _apiClient.post<Notification>(
        '${ApiConfig.pathNotifications}/$notificationId/lue',
        data: {},
        fromJson: (json) =>
            Notification.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Notification marquée comme lue');
      return response;
    } catch (e) {
      _logger.e('Erreur lors du marquage comme lue: $e');
      rethrow;
    }
  }

  /// Marque toutes les notifications comme lues (alias)
  Future<Notification> marquerCommeEue(String notificationId) async {
    return marquerCommeLue(notificationId);
  }

  /// Marque toutes les notifications comme lues
  Future<void> marquerToutesCommeEues() async {
    try {
      _logger.i('Marquage de toutes les notifications comme lues');

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathNotifications}/marquer-toutes-lues',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Toutes les notifications marquées comme lues');
    } catch (e) {
      _logger.e('Erreur lors du marquage de toutes les notifications: $e');
      rethrow;
    }
  }

  /// Supprime une notification
  Future<void> supprimerNotification(String notificationId) async {
    try {
      _logger.i('Suppression notification: $notificationId');

      await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConfig.pathNotifications}/$notificationId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Notification supprimée');
    } catch (e) {
      _logger.e('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Compte les notifications non lues
  Future<int> comptorNotificationsNonLues() async {
    try {
      _logger.i('Comptage notifications non lues');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.pathNotifications}/non-lues/count',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final count = response['count'] as int? ?? 0;
      _logger.i('$count notifications non lues');
      return count;
    } catch (e) {
      _logger.e('Erreur lors du comptage: $e');
      rethrow;
    }
  }
}
