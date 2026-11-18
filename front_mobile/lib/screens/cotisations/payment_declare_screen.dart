import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cotisations_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';

/// Écran de déclaration de paiement (étape 1/2)
/// 
/// Permet de déclarer un paiement effectué pour une cotisation.
/// 
/// Endpoints API utilisés:
/// - POST /cotisations/:id/paiement (déclarer paiement)
class PaymentDeclareScreen extends ConsumerStatefulWidget {
  final String cotisationId;
  final Cotisation cotisation;

  const PaymentDeclareScreen({
    super.key,
    required this.cotisationId,
    required this.cotisation,
  });

  @override
  ConsumerState<PaymentDeclareScreen> createState() =>
      _PaymentDeclareScreenState();
}

class _PaymentDeclareScreenState extends ConsumerState<PaymentDeclareScreen> {
  String? _selectedOperateur;
  final _referenceController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  final List<Map<String, String>> _operateurs = [
    {'label': 'Orange Money', 'value': 'orange_money'},
    {'label': 'MTN Money', 'value': 'mtn_money'},
    {'label': 'Virement Bancaire', 'value': 'virement_bancaire'},
    {'label': 'Autre', 'value': 'autre'},
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  /// Valide et soumet la déclaration
  Future<void> _declare() async {
    // Valider les champs
    if (_selectedOperateur == null) {
      setState(() {
        _error = 'Veuillez sélectionner un opérateur';
      });
      return;
    }

    if (_referenceController.text.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer la référence de transaction';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // La requête est signée par le client ; le serveur ne garde que la référence.
      await ref.read(cotisationsServiceProvider).declarerPaiement(
        cotisationId: widget.cotisationId,
        referenceTransaction: _referenceController.text,
      );
      ref.invalidate(mesCotisationsRefreshableProvider);

      // Le bénéficiaire doit maintenant confirmer la réception.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paiement déclaré. Le bénéficiaire doit confirmer la réception.'),
        ));
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarer un Paiement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Étape
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Étape 1 de 2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Résumé de la cotisation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cotisation à Payer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Montant',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          formatAmount(widget.cotisation.montant),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          widget.cotisation.beneficiaireId,
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
                          'Date limite',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          formatDate(widget.cotisation.dateLimite),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sélection opérateur
              const Text(
                'Opérateur de Paiement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedOperateur,
                items: _operateurs
                    .map((op) => DropdownMenuItem(
                          value: op['value'],
                          child: Text(op['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOperateur = value;
                    _error = null;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Choisir un opérateur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Référence transaction
              const Text(
                'Référence de Transaction',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Ex: 123456789 (13 chiffres pour Mobile Money)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _error != null && _selectedOperateur != null
                      ? _error
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'ℹ️ Assurez-vous d\'avoir effectué le paiement avant de le déclarer. '
                  'Vous devrez fournir une preuve à l\'étape suivante.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Bouton
              AppButton(
                label: _isLoading ? 'Déclaration en cours...' : 'Continuer',
                onPressed: _isLoading ? null : _declare,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
