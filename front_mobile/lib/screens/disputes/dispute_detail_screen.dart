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

                  // Seul un administrateur MonDo tranche un litige : le membre suit.
                  if (litige.statut == 'ouvert')
                    const _DetailCard(
                      title: 'Et maintenant ?',
                      content:
                          'Un administrateur MonDo examine le litige et tranche. Tu seras notifié de sa décision.',
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  late final Future<Litige> _litige =
      ref.read(litigesServiceProvider).getLitige(widget.litigeId);

  Future<Litige> _fetchLitige() => _litige;

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
          Icon(Icons.gavel_rounded, color: _getColor(), size: 32),
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
