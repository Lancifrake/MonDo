import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sobre.dart';

/// Mon score de confiance (GET /score/:moi), son explication et son historique.
class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(monScoreRefreshableProvider);
    String evenement(String t) => switch (t) {
          'cotisation_a_temps' => 'Cotisation à temps',
          'cotisation_en_retard' => 'Cotisation en retard',
          'defaut' || 'defaut_constate' => 'Défaut',
          'fin_de_cycle' || 'bonus_fin_de_cycle' => 'Cycle terminé sans défaut',
          _ => t.replaceAll('_', ' '),
        };
    return Ecran(
      titre: 'Mon score',
      enfants: selon(score, (s) => [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${s.score}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w600, height: 1)),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 8),
                child: Text('sur 100', style: TextStyle(color: AppColors.textMuted)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              s.premieresPlacesFermees ? 'Premières places fermées après un défaut' : 'Le score ouvre l’accès aux premières places',
              style: styleStatut(s.premieresPlacesFermees ? Ton.action : Ton.gris),
            ),
            const SizedBox(height: 12),
            Bloc(enfants: [
              Ligne('Cycles terminés', valeur: '${s.cyclesTermines}'),
              Ligne('Défauts', valeur: '${s.defauts}', accent: s.defauts > 0),
            ]),
            if (s.explication.isNotEmpty) ...[
              const Titre('Comment il se calcule'),
              for (final ligne in s.explication) Note(ligne),
            ],
            const Titre('Historique'),
            if (s.historique.isEmpty) const Note('Rien encore : ton score évolue à chaque cotisation.'),
            if (s.historique.isNotEmpty)
              Bloc(enfants: [
                for (final e in s.historique.reversed)
                  Ligne(
                    '${evenement(e.type)} · ${dateCourte(e.date)}',
                    valeur: '${e.points >= 0 ? '+' : ''}${e.points}  →  ${e.scoreApres}',
                    accent: e.points < 0,
                  ),
              ]),
          ], reessayer: () => ref.invalidate(monScoreRefreshableProvider)),
    );
  }
}
