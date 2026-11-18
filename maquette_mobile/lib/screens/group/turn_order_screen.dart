import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../data/group_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/rules_format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class TurnOrderScreen extends StatelessWidget {
  const TurnOrderScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    final p = tontine.progress;

    return Scaffold(
      appBar: buildAppBar(context, 'Ordre des tours'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: p == null
            ? _notStarted()
            : _started(context, p),
      ),
    );
  }

  // Tontine en préparation : l'ordre n'est pas encore tiré
  List<Widget> _notStarted() {
    return [
      const SizedBox(height: 16),
      AppCard(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textMuted,
              ),
              children: [
                const TextSpan(
                  text: "L'ordre sera fixé au démarrage de la tontine. "
                      'Méthode choisie : ',
                ),
                TextSpan(
                  text: orderLabel(tontine.rules.orderMode),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];
  }

  // Tontine démarrée : l'ordre, qui a reçu, et la vérification du tirage
  List<Widget> _started(BuildContext context, TontineProgress p) {
    return [
      Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textMuted,
          ),
          children: [
            const TextSpan(text: 'Méthode : '),
            TextSpan(
              text: orderLabel(tontine.rules.orderMode),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const TextSpan(text: '. Public, vérifiable par tous.'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < p.order.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _TurnRow(
                position: i + 1,
                name: p.order[i],
                isMe: p.order[i] == p.me,
                currentTurn: p.currentTurn,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérifier que le tirage est honnête',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Le tirage a été fait avec une graine publiée. Avec la même '
              'graine et les mêmes membres, tout le monde obtient le même ordre.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              'Graine publiée',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                p.seed,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Rejouer le tirage',
              background: Colors.white,
              foreground: AppColors.textDark,
              borderColor: AppColors.border,
              onPressed: () {
                // La vraie vérification (même graine, même ordre) se fera
                // avec le serveur : on n'affiche donc pas de faux résultat.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La vérification du tirage arrive bientôt'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.position,
    required this.name,
    required this.isMe,
    required this.currentTurn,
  });

  final int position;
  final String name;
  final bool isMe;
  final int currentTurn;

  @override
  Widget build(BuildContext context) {
    Widget? badge;
    if (position < currentTurn) {
      badge = const StatusBadge(
        label: 'A reçu',
        background: Color(0xFFEBEDE7),
        foreground: AppColors.textMuted,
      );
    } else if (position == currentTurn) {
      badge = const StatusBadge(
        label: 'Tour en cours',
        background: AppColors.mint,
        foreground: AppColors.green,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$position',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '$name (toi)' : name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }
}