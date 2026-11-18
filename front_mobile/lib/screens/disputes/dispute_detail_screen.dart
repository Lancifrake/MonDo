import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/litiges_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';

/// Écran de détails d'un litige
/// 
/// Affiche les détails d'un litige spécifique et permet
/// de prendre une décision si l'utilisateur est arbitre.
/// 
/// Endpoints API utilisés:
/// - GET /litiges/:id (récupérer détails)
/// - POST /litiges/:id/decision (soumettre une décision)
class DisputeDetailScreen extends ConsumerStatefulWidget {
  final String litigeId;

  const DisputeDetailScreen({
    super.key,
    required this.litigeId,
  });

  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  bool _isDeciding = false;
  String? _selectedDecision;
  final _motifController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer détails du litige (utiliser une requête directe pour simplifier)
    // Dans une vraie app, créer un provider pour un litige spécifique
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Litige'),
        elevation: 0,
      ),
      body: FutureBuilder<Litige>(
        future: _fetchLitige(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final litige = snapshot.data;
          if (litige == null) {
            return const Center(
              child: Text('Litige non trouvé'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statut
                  _StatusCard(statut: litige.statut),

                  const SizedBox(height: 24),

                  // Motif
                  _DetailCard(
                    title: 'Motif',
                    content: litige.motif,
                  ),

                  const SizedBox(height: 24),

                  // Parties impliquées
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
                          'Parties Impliquées',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PartyRow(
                          label: 'Payeur',
                          value: litige.payeurId,
                        ),
                        const SizedBox(height: 8),
                        _PartyRow(
                          label: 'Bénéficiaire',
                          value: litige.beneficiaireId,
                        ),
                        const SizedBox(height: 8),
                        _PartyRow(
                          label: 'Ouvert par',
                          value: litige.ouvertPar,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dates
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
                          'Calendrier',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DateRow(
                          label: 'Ouvert le',
                          value: formatDate(litige.ouvertLe),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Décision si tranché
                  if (litige.statut != 'ouvert') ...[
                    _DetailCard(
                      title: 'Décision',
                      content: litige.decision ?? 'En attente de décision',
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Formulaire de décision si ouvert et utilisateur peut décider
                  if (litige.statut == 'ouvert') ...[
                    const Text(
                      'Soumettre une Décision',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DecisionForm(
                      onSubmit: (decision, motif) =>
                          _submitDecision(decision, motif),
                      isLoading: _isDeciding,
                      error: _error,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Litige> _fetchLitige() async {
    // TODO: Implémenter requête GET /litiges/:id
    // Pour maintenant, retourner un litige mock
    throw Exception('À implémenter');
  }

  Future<void> _submitDecision(String decision, String motif) async {
    setState(() {
      _isDeciding = true;
      _error = null;
    });

    try {
      // Appel API
      final apiClient = ref.read(apiClientProvider);

      final payload = {
        'decision': decision,
        'motifDecision': motif,
      };

      // TODO: Utiliser LitigesService.decider()
      await apiClient.post<Map<String, dynamic>>(
        '/litiges/${widget.litigeId}/decision',
        data: payload,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Décision soumise avec succès ! ✅'),
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
        _isDeciding = false;
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
        _isDeciding = false;
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

/// Card de statut
class _StatusCard extends StatelessWidget {
  final String statut;

  const _StatusCard({required this.statut});

  Color _getColor() {
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

  String _getLabel() {
    switch (statut) {
      case 'ouvert':
        return 'Litige Ouvert';
      case 'tranche':
        return 'Litige Tranché';
      case 'clos':
        return 'Litige Clos';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getColor(), size: 32),
          const SizedBox(width: 12),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de détail
class _DetailCard extends StatelessWidget {
  final String title;
  final String content;

  const _DetailCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de partie
class _PartyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PartyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Ligne de date
class _DateRow extends StatelessWidget {
  final String label;
  final String value;

  const _DateRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Formulaire de décision
class _DecisionForm extends StatefulWidget {
  final Function(String decision, String motif) onSubmit;
  final bool isLoading;
  final String? error;

  const _DecisionForm({
    required this.onSubmit,
    required this.isLoading,
    required this.error,
  });

  @override
  State<_DecisionForm> createState() => _DecisionFormState();
}

class _DecisionFormState extends State<_DecisionForm> {
  String? _selectedDecision;
  final _motifController = TextEditingController();

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Décision',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDecision,
          items: [
            const DropdownMenuItem(
              value: 'favor_payeur',
              child: Text('En faveur du payeur'),
            ),
            const DropdownMenuItem(
              value: 'favor_beneficiaire',
              child: Text('En faveur du bénéficiaire'),
            ),
            const DropdownMenuItem(
              value: 'transaction',
              child: Text('Transaction'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDecision = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Sélectionner une décision',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Motif de la Décision',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _motifController,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Expliquez votre décision...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        if (widget.error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
        if (widget.error != null) const SizedBox(height: 12),
        AppButton(
          label: widget.isLoading
              ? 'Soumission en cours...'
              : 'Soumettre la Décision',
          onPressed: widget.isLoading || _selectedDecision == null
              ? null
              : () => widget.onSubmit(_selectedDecision!, _motifController.text),
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}
