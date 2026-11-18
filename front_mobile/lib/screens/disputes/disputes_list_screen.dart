import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/litiges_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import 'dispute_detail_screen.dart';
import 'open_dispute_screen.dart';

/// Écran de liste des litiges
/// 
/// Affiche tous les litiges de l'utilisateur (ouverts, tranchés, clos)
/// avec possibilité de filtrer par statut.
/// 
/// Endpoints API utilisés:
/// - GET /litiges/miens (récupérer mes litiges)
class DisputesListScreen extends ConsumerStatefulWidget {
  const DisputesListScreen({super.key});

  @override
  ConsumerState<DisputesListScreen> createState() =>
      _DisputesListScreenState();
}

class _DisputesListScreenState extends ConsumerState<DisputesListScreen> {
  String _selectedFilter = 'all'; // all, ouvert, tranche, clos

  @override
  Widget build(BuildContext context) {
    // Récupérer mes litiges
    final litiquesAsync = ref.watch(mesLitigesRefreshableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Litiges'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OpenDisputeScreen(),
                ),
              );
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
                  _buildFilterChip('all', 'Tous'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ouvert', 'Ouverts'),
                  const SizedBox(width: 8),
                  _buildFilterChip('tranche', 'Tranchés'),
                  const SizedBox(width: 8),
                  _buildFilterChip('clos', 'Clos'),
                ],
              ),
            ),
          ),

          // Liste des litiges
          Expanded(
            child: litiquesAsync.when(
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
                          ref.refresh(mesLitigesRefreshableProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (litiges) {
                // Filtrer les litiges
                final filtered = litiges.where((l) {
                  if (_selectedFilter == 'all') {
                    return true;
                  }
                  return l.statut == _selectedFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.done_outline,
                          size: 64,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Aucun litige'
                              : 'Aucun litige $_selectedFilter',
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
                    ref.refresh(mesLitigesRefreshableProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final litige = filtered[index];
                      return _LitigeCard(
                        litige: litige,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DisputeDetailScreen(
                                litigeId: litige.id,
                              ),
                            ),
                          );
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

/// Card pour afficher un litige
class _LitigeCard extends StatelessWidget {
  final Litige litige;
  final VoidCallback onTap;

  const _LitigeCard({
    required this.litige,
    required this.onTap,
  });

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'ouvert':
        return Colors.red;
      case 'tranche':
        return Colors.orange;
      case 'clos':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'ouvert':
        return 'Ouvert';
      case 'tranche':
        return 'Tranché';
      case 'clos':
        return 'Clos';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motif',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          litige.motif,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(litige.statut).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(litige.statut),
                      style: TextStyle(
                        color: _getStatusColor(litige.statut),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Détails
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ouvert par',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        litige.ouvertPar.substring(0, 12) + '...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Date d\'ouverture',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(litige.ouvertLe),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Décision si tranchée
              if (litige.statut != 'ouvert' && litige.decision != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Décision',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        litige.decision!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
