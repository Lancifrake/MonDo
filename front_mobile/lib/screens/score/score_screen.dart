import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';

/// Écran affichage du score de confiance
/// 
/// Affiche le score de confiance de l'utilisateur et son historique,
/// avec explications des événements qui ont affecté le score.
/// 
/// Endpoints API utilisés:
/// - GET /score/:membreId (récupérer score)
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer le score de l'utilisateur
    // TODO: Remplacer par vraie implémentation - utiliser l'ID du membre connecté
    final monScoreAsync = ref.watch(monScoreRefreshableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Score'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(monScoreRefreshableProvider),
          ),
        ],
      ),
      body: monScoreAsync.when(
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
                onPressed: () => ref.refresh(monScoreRefreshableProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (score) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec score principal
                _ScoreHeader(score: score),

                const SizedBox(height: 24),

                // Explications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ScoreExplanation(score: score),
                ),

                const SizedBox(height: 24),

                // Restrictions
                if (score.premieresPlacesFermees == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _RestrictionCard(
                      title: 'Restriction Active',
                      message: 'Vos premières places sont fermées jusqu\'à '
                          'amélioration de votre score.',
                    ),
                  ),

                const SizedBox(height: 24),

                // Historique
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HistoriqueSection(score: score),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// En-tête avec le score principal
class _ScoreHeader extends StatelessWidget {
  final ScoreMembre score;

  const _ScoreHeader({required this.score});

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score.score);
    final scoreLabel = _getScoreLabel(score.score);

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Score de Confiance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Score circulaire
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.1),
              border: Border.all(
                color: scoreColor,
                width: 4,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.score.toString(),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score.score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${score.score}/100',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '100',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section explication du score
class _ScoreExplanation extends StatelessWidget {
  final ScoreMembre score;

  const _ScoreExplanation({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'À Propos de Votre Score',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (score.explication != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              score.explication!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blue,
                height: 1.5,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Votre score reflète votre fiabilité et votre respect des '
              'engagements au sein des cercles. Les paiements à temps '
              'augmentent votre score, les retards le réduisent.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Card de restriction
class _RestrictionCard extends StatelessWidget {
  final String title;
  final String message;

  const _RestrictionCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section historique
class _HistoriqueSection extends StatelessWidget {
  final ScoreMembre score;

  const _HistoriqueSection({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des Événements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (score.historique == null || score.historique!.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'Aucun événement enregistré',
                style: TextStyle(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: score.historique!.length,
            itemBuilder: (context, index) {
              final event = score.historique![index];
              return _EvenementCard(event: event);
            },
          ),
      ],
    );
  }
}

/// Card pour un événement
class _EvenementCard extends StatelessWidget {
  final EvenementScore event;

  const _EvenementCard({required this.event});

  Color _getDeltaColor() {
    if (event.delta > 0) return Colors.green;
    if (event.delta < 0) return Colors.red;
    return Colors.grey;
  }

  String _getEventLabel() {
    // Mapper les types d'événements
    switch (event.type) {
      case 'paiement_a_temps':
        return 'Paiement à temps';
      case 'paiement_retard':
        return 'Paiement en retard';
      case 'paiement_defaut':
        return 'Défaut de paiement';
      case 'remboursement':
        return 'Remboursement';
      case 'litige_ouvert':
        return 'Litige ouvert';
      case 'litige_clos':
        return 'Litige clos';
      default:
        return event.type;
    }
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case 'paiement_a_temps':
        return Icons.check_circle;
      case 'paiement_retard':
        return Icons.warning_rounded;
      case 'paiement_defaut':
        return Icons.cancel;
      case 'remboursement':
        return Icons.undo;
      case 'litige_ouvert':
        return Icons.gavel;
      case 'litige_clos':
        return Icons.check_box;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deltaColor = _getDeltaColor();
    final isPositive = event.delta > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEventIcon(),
              color: deltaColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEventLabel(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateTimeRelative(event.creeLe),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Delta
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${event.delta}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: deltaColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
