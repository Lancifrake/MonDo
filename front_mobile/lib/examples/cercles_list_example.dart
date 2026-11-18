import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../providers/cercles_provider.dart';
import '../providers/notifications_provider.dart';

/// EXEMPLE D'INTÉGRATION - Écran de liste des cercles
/// 
/// Cet exemple montre comment afficher la liste des cercles
/// et interagir avec les providers Riverpod
class CerclesListExample extends ConsumerWidget {
  const CerclesListExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarder les providers
    final cerclesAsync = ref.watch(mesCerclesRefreshableProvider);
    final notificationsCountAsync =
        ref.watch(comptNotificationsNonLuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes cercles'),
        actions: [
          // Badge de notifications
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: notificationsCountAsync.when(
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: cerclesAsync.when(
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
                    ref.refresh(mesCerclesRefreshableProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (cercles) => cercles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.circle_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text('Aucun cercle pour le moment'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/create_cercle');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un cercle'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(mesCerclesRefreshableProvider);
                  // Attendre le résultat
                  await ref.read(mesCerclesRefreshableProvider.future);
                },
                child: ListView.builder(
                  itemCount: cercles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == cercles.length) {
                      // Bouton en bas pour créer un cercle
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigator.pushNamed(context, '/create_cercle');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un nouveau cercle'),
                        ),
                      );
                    }

                    final cercle = cercles[index];
                    return CercleCard(cercle: cercle);
                  },
                ),
              ),
      ),
    );
  }
}

/// Card pour afficher un résumé du cercle
class CercleCard extends ConsumerWidget {
  final ResumeCercle cercle;

  const CercleCard({
    Key? key,
    required this.cercle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Couleur du statut
    final statusColor = _getStatusColor(cercle.statut);
    final statusLabel = _getStatusLabel(cercle.statut);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => CercleDetailScreen(cercleId: cercle.id),
          //   ),
          // );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cercle.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Détails
              Row(
                children: [
                  _DetailItem(
                    icon: Icons.people,
                    label: '${cercle.nombreMembres}/${cercle.nombreMembresCible}',
                  ),
                  const SizedBox(width: 16),
                  _DetailItem(
                    icon: Icons.attach_money,
                    label: '${cercle.montantTotal} F',
                  ),
                  const SizedBox(width: 16),
                  _DetailItem(
                    icon: Icons.calendar_today,
                    label: cercle.frequence ?? 'N/A',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Naviguer vers les détails du cercle
                    // Navigator.push(context, ...);
                  },
                  child: const Text('Voir les détails'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'complet':
        return Colors.blue;
      case 'termine':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'complet':
        return 'Complet';
      case 'termine':
        return 'Terminé';
      default:
        return statut;
    }
  }
}

/// Widget auxiliaire pour afficher un détail
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
