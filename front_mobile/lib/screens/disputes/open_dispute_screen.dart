import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';

/// Écran pour ouvrir un nouveau litige
/// 
/// Permet à l'utilisateur d'ouvrir un litige concernant
/// une cotisation spécifique.
/// 
/// Endpoints API utilisés:
/// - POST /litiges (ouvrir un nouveau litige)
/// - GET /cotisations (pour sélectionner la cotisation)
class OpenDisputeScreen extends ConsumerStatefulWidget {
  const OpenDisputeScreen({super.key});

  @override
  ConsumerState<OpenDisputeScreen> createState() => _OpenDisputeScreenState();
}

class _OpenDisputeScreenState extends ConsumerState<OpenDisputeScreen> {
  String? _selectedCotisationId;
  final _motifController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les cotisations pour sélection
    final cotisationsAsync = ref.watch(mesCotisationsRefreshableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ouvrir un Litige'),
        elevation: 0,
      ),
      body: cotisationsAsync.when(
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
                    ref.refresh(mesCotisationsRefreshableProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (cotisations) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      '⚠️ Ouvrez un litige pour contester un paiement ou signaler '
                      'une problématique. Un arbitrage sera effectué selon '
                      'le réglement du cercle.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sélection cotisation
                  const Text(
                    'Cotisation Concernée',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (cotisations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Aucune cotisation disponible',
                        style: TextStyle(
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCotisationId,
                      items: cotisations
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.beneficiaireId} - ${formatAmount(c.montant)}',
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCotisationId = value;
                          _error = null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Sélectionner une cotisation',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Résumé cotisation
                  if (_selectedCotisationId != null) ...[
                    _CotisationResume(
                      cotisation: cotisations.firstWhere(
                        (c) => c.id == _selectedCotisationId,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Motif du litige
                  const Text(
                    'Motif du Litige',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _motifController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Décrivez le problème rencontré avec cette cotisation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Affichage d'erreur
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),

                  if (_error != null) const SizedBox(height: 16),

                  // Boutons
                  AppButton(
                    label: _isLoading
                        ? 'Ouverture en cours...'
                        : 'Ouvrir le Litige',
                    onPressed:
                        _isLoading || _selectedCotisationId == null
                            ? null
                            : _openDispute,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDispute() async {
    // Valider
    if (_selectedCotisationId == null) {
      setState(() {
        _error = 'Veuillez sélectionner une cotisation';
      });
      return;
    }

    if (_motifController.text.isEmpty) {
      setState(() {
        _error = 'Veuillez décrire le motif du litige';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Appel API
      final apiClient = ref.read(apiClientProvider);

      final payload = {
        'cotisationId': _selectedCotisationId,
        'motif': _motifController.text,
      };

      // TODO: Utiliser LitigesService.ouvrirLitige()
      final response = await apiClient.post<Map<String, dynamic>>(
        '/litiges',
        data: payload,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Litige ouvert avec succès ! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Retour après 2 secondes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur inattendue: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Résumé de la cotisation sélectionnée
class _CotisationResume extends StatelessWidget {
  final Cotisation cotisation;

  const _CotisationResume({required this.cotisation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Montant',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                formatAmount(cotisation.montant),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bénéficiaire',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                cotisation.beneficiaireId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statut',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                cotisation.statut.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cotisation.statut == 'due'
                      ? Colors.red
                      : cotisation.statut == 'declaree'
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
