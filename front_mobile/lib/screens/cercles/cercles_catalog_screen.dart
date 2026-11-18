import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cercles_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import 'cercle_details_screen.dart';

/// Écran catalogue de cercles ouverts
/// 
/// Affiche tous les cercles ouverts et non complets,
/// avec possibilité de filtrer par montant, fréquence, etc.
/// 
/// Endpoints API utilisés:
/// - GET /cercles/catalogue?montantMin=...&montantMax=...&frequence=...
class CerclesCatalogScreen extends ConsumerStatefulWidget {
  const CerclesCatalogScreen({super.key});

  @override
  ConsumerState<CerclesCatalogScreen> createState() =>
      _CerclesCatalogScreenState();
}

class _CerclesCatalogScreenState extends ConsumerState<CerclesCatalogScreen> {
  int? _montantMin;
  int? _montantMax;
  String? _frequence;
  int? _nombreMembreMax;

  final _frequences = ['hebdomadaire', 'bimensuelle', 'mensuelle', 'trimestrielle', 'annuelle'];

  @override
  Widget build(BuildContext context) {
    // Récupérer le catalogue avec filtres
    final filter = CatalogueFilter(
      montantMin: _montantMin,
      montantMax: _montantMax,
      frequence: _frequence,
      nombreMembreMax: _nombreMembreMax,
    );
    final catalogueAsync = ref.watch(catalogueCerclesProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir des Cercles'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton expansible pour filtres avancés
                GestureDetector(
                  onTap: () => _showFilterDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Filtres'),
                          ],
                        ),
                        _getActiveFiltersCount() > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_getActiveFiltersCount()} actif(s)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des cercles
          Expanded(
            child: catalogueAsync.when(
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
                      onPressed: () => ref.refresh(catalogueCerclesProvider(filter)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (cercles) {
                if (cercles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text('Aucun cercle trouvé avec ces filtres'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _montantMin = null;
                              _montantMax = null;
                              _frequence = null;
                              _nombreMembreMax = null;
                            });
                          },
                          child: const Text('Réinitialiser filtres'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(catalogueCerclesProvider(filter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cercles.length,
                    itemBuilder: (context, index) {
                      final cercle = cercles[index];
                      return _CercleCard(
                        cercle: cercle,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CercleDetailsScreen(cercleId: cercle.id),
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

  int _getActiveFiltersCount() {
    int count = 0;
    if (_montantMin != null) count++;
    if (_montantMax != null) count++;
    if (_frequence != null) count++;
    if (_nombreMembreMax != null) count++;
    return count;
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Montant minimum
                  const Text(
                    'Montant minimum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 10000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        _montantMin = int.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Montant maximum
                  const Text(
                    'Montant maximum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 100000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        _montantMax = int.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fréquence
                  const Text(
                    'Fréquence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _frequences
                        .map((freq) => FilterChip(
                              label: Text(freq),
                              selected: _frequence == freq,
                              onSelected: (selected) {
                                setStateModal(() {
                                  _frequence = selected ? freq : null;
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Nombre de membres maximum
                  const Text(
                    'Nombre de membres max',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setStateModal(() {
                        _nombreMembreMax = int.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _montantMin = null;
                              _montantMax = null;
                              _frequence = null;
                              _nombreMembreMax = null;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Card pour un cercle dans le catalogue
class _CercleCard extends StatelessWidget {
  final Cercle cercle;
  final VoidCallback onTap;

  const _CercleCard({
    required this.cercle,
    required this.onTap,
  });

  int _getProgressPercent() {
    if (cercle.reglement.nombreMembres == 0) return 0;
    return ((cercle.membres.length / cercle.reglement.nombreMembres) * 100)
        .toInt();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cercle.nom ?? 'Cercle',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (cercle.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            cercle.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OUVERT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Infos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColumn(
                    label: 'Montant',
                    value: formatAmount(cercle.reglement.montant),
                  ),
                  _InfoColumn(
                    label: 'Fréquence',
                    value: cercle.reglement.frequence.substring(0, 1).toUpperCase() +
                        cercle.reglement.frequence.substring(1),
                  ),
                  _InfoColumn(
                    label: 'Membres',
                    value:
                        '${cercle.membres.length}/${cercle.reglement.nombreMembres}',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getProgressPercent() / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    cercle.membres.length == cercle.reglement.nombreMembres
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Texte progression
              Text(
                '${_getProgressPercent()}% complet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colonne d'info simple
class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
