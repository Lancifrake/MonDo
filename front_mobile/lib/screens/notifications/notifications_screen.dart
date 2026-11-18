import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/notifications_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';

/// Écran de notifications
/// 
/// Affiche toutes les notifications de l'utilisateur avec
/// possibilité de les marquer comme lues.
/// 
/// Endpoints API utilisés:
/// - GET /notifications (récupérer notifications)
/// - POST /notifications/:id/lue (marquer comme lue)
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // all, non_lues, lues

  @override
  Widget build(BuildContext context) {
    // Récupérer les notifications
    final notificationsAsync = ref.watch(meNotificationsRefreshableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(meNotificationsRefreshableProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('non_lues', 'Non lues'),
                  const SizedBox(width: 8),
                  _buildFilterChip('lues', 'Lues'),
                ],
              ),
            ),
          ),

          // Liste des notifications
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(meNotificationsRefreshableProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (notifications) {
                // Filtrer les notifications
                final filtered = notifications.where((n) {
                  if (_selectedFilter == 'non_lues') {
                    return !n.lue;
                  } else if (_selectedFilter == 'lues') {
                    return n.lue;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Aucune notification'
                              : 'Aucune notification ${_selectedFilter == 'non_lues' ? 'non lue' : 'lue'}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(meNotificationsRefreshableProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationCard(
                        notification: notification,
                        onMarkRead: () {
                          _markAsRead(notification.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Marquer une notification comme lue
  Future<void> _markAsRead(String notificationId) async {
    try {
      final notificationsService = ref.read(notificationsServiceProvider);
      await notificationsService.marquerCommeLue(notificationId);

      // Rafraîchir la liste
      ref.refresh(meNotificationsRefreshableProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification marquée comme lue'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// Card pour afficher une notification
class _NotificationCard extends StatelessWidget {
  final Notification notification;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'cotisation':
        return Icons.payments;
      case 'cercle':
        return Icons.group;
      case 'litige':
        return Icons.gavel;
      case 'score':
        return Icons.star;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'cotisation':
        return Colors.blue;
      case 'cercle':
        return Colors.green;
      case 'litige':
        return Colors.red;
      case 'score':
        return Colors.amber;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onMarkRead,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getColorForType(notification.type)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      color: _getColorForType(notification.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.titre,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notification.lue
                                      ? FontWeight.normal
                                      : FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.lue)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatDateTimeRelative(notification.dateCreation),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Menu
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!notification.lue)
                        PopupMenuItem(
                          onTap: onMarkRead,
                          child: const Row(
                            children: [
                              Icon(Icons.done, size: 18),
                              SizedBox(width: 8),
                              Text('Marquer comme lue'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        onTap: () {
                          // TODO: Implémenter suppression
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
