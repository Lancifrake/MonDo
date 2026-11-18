import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cercles/vie_cercle_screens.dart';
import '../../providers/api_client_provider.dart';
import '../../services/api_client.dart';
import '../../models/api_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import 'payment_declare_screen.dart';

/// Écran de liste des cotisations
/// 
/// Affiche toutes les cotisations dues de l'utilisateur,
/// filtrées par cercle et statut.
/// 
/// Endpoints API utilisés:
/// - GET /cercles (pour filtrer par cercle)
/// - GET /cotisations?cercleId=... (liste cotisations)
class CotisationsListScreen extends ConsumerStatefulWidget {
  const CotisationsListScreen({super.key});

  @override
  ConsumerState<CotisationsListScreen> createState() =>
      _CotisationsListScreenState();
}

class _CotisationsListScreenState extends ConsumerState<CotisationsListScreen> {
  String? _selectedCercleId;
  String _selectedStatut = 'due'; // due, declaree, confirmee

  @override
  Widget build(BuildContext context) {
    // Récupérer les cercles de l'utilisateur pour le filtre
    final mesCerclesAsync = ref.watch(mesCerclesRefreshableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cotisations'),
        elevation: 0,
      ),
      body: mesCerclesAsync.when(
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
        data: (resumeCercles) {
          // Sélectionner le premier cercle par défaut
          _selectedCercleId ??= resumeCercles.isNotEmpty ? resumeCercles.first.id : null;

          return Column(
            children: [
              // Filtres
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtre cercle
                    const Text(
                      'Cercle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCercleId,
                      items: resumeCercles
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nom),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCercleId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtre statut
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusFilter('due', 'À payer'),
                          const SizedBox(width: 8),
                          _buildStatusFilter('declaree', 'Déclarée'),
                          const SizedBox(width: 8),
                          _buildStatusFilter('confirmee', 'Confirmée'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des cotisations
              Expanded(
                child: _selectedCercleId == null
                    ? const Center(
                        child: Text('Aucun cercle disponible'),
                      )
                    : _CotisationsListContent(
                        cercleId: _selectedCercleId!,
                        statut: _selectedStatut,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilter(String statut, String label) {
    final isSelected = _selectedStatut == statut;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatut = statut;
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

/// Widget interne pour afficher la liste des cotisations
class _CotisationsListContent extends ConsumerWidget {
  final String cercleId;
  final String statut;

  const _CotisationsListContent({
    required this.cercleId,
    required this.statut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer les cotisations filtrées
    final cotisationsAsync = ref.watch(
      mesCotisationsFiltreesProvider(statut),
    );

    return cotisationsAsync.when(
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
                  ref.refresh(mesCotisationsFiltreesProvider(statut)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (cotisations) {
        // Filtrer par cercle sélectionné
        final cotisationsFiltered =
            cotisations.where((c) => c.cercleId == cercleId).toList();

        if (cotisationsFiltered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.done_all,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 16),
                const Text('Aucune cotisation pour ce filtre'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(mesCotisationsFiltreesProvider(statut));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cotisationsFiltered.length,
            itemBuilder: (context, index) {
              final cotisation = cotisationsFiltered[index];
              final moi = ref.read(apiClientProvider).membreId;
              return _CotisationCard(
                cotisation: cotisation,
                moi: moi,
                onConfirm: () => _confirmerReception(context, ref, cotisation),
                onPay: () {
                  // Naviguer vers écran de déclaration de paiement
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentDeclareScreen(
                        cotisationId: cotisation.id,
                        cotisation: cotisation,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Card pour afficher une cotisation
/// Le bénéficiaire confirme avoir reçu l'argent (POST /cotisations/:id/confirmation).
Future<void> _confirmerReception(BuildContext context, WidgetRef ref, Cotisation c) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmer la réception ?'),
      content: Text(
        'Tu confirmes avoir reçu ${formatAmount(c.montant)} FCFA'
        '${c.referenceTransaction != null ? ' (référence ${c.referenceTransaction})' : ''}. '
        'Cette confirmation est inscrite au registre.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Je confirme')),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await ref.read(cotisationsServiceProvider).confirmerPaiement(cotisationId: c.id);
    ref.invalidate(mesCotisationsRefreshableProvider);
    ref.invalidate(mesCotisationsFiltreesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réception confirmée.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Erreur : $e')),
      );
    }
  }
}

class _CotisationCard extends StatelessWidget {
  final Cotisation cotisation;
  final String? moi;
  final VoidCallback onPay;
  final VoidCallback onConfirm;

  const _CotisationCard({
    required this.cotisation,
    required this.moi,
    required this.onPay,
    required this.onConfirm,
  });

  bool get _jeDois => cotisation.payeurId == moi;

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'due':
        return Colors.red;
      case 'declaree':
        return Colors.orange;
      case 'confirmee':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'due':
        return 'À payer';
      case 'declaree':
        return 'Déclarée';
      case 'confirmee':
        return 'Confirmée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bénéficiaire',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cotisation.beneficiaireId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(cotisation.statut).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(cotisation.statut),
                    style: TextStyle(
                      color: _getStatusColor(cotisation.statut),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Montant',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatAmount(cotisation.montant),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Date limite',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(cotisation.dateLimite),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              _jeDois ? 'Je dois · tour ${cotisation.tour}' : 'On me doit · tour ${cotisation.tour}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),

            // Le bénéficiaire confirme ce que le payeur a déclaré
            if (cotisation.statut == 'declaree' && !_jeDois)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Confirmer la réception'),
                ),
              ),

            // Le payeur déclare son paiement
            if (cotisation.statut == 'due' && _jeDois)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPay,
                  child: const Text("J'ai payé : déclarer"),
                ),
              ),
            if (cotisation.statut == 'due' && _jeDois)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaiementSimuleScreen(cotisation: cotisation)),
                ),
                child: const Text('Payer par Mobile Money (démo)'),
              ),
          ],
        ),
      ),
    );
  }
}
