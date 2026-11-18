import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/catalog_tontine_card.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/two_column_grid.dart';
import 'tontine_detail_screen.dart';
import 'join_with_code_screen.dart';

class FindTontineScreen extends StatefulWidget {
  const FindTontineScreen({super.key});

  @override
  State<FindTontineScreen> createState() => _FindTontineScreenState();
}

class _FindTontineScreenState extends State<FindTontineScreen> {
  static const _amountOptions = {
    'all': 'Tous les montants',
    'upTo25': "Jusqu'à 25 000 F",
    'from25to50': '25 000 à 50 000 F',
    'over50': 'Plus de 50 000 F',
  };

  static const _frequencyOptions = {
    'all': 'Tous',
    'weekly': 'Semaine',
    'monthly': 'Mois',
  };

  String _amount = 'all';
  String _frequency = 'all';

  bool _matchesAmount(int amount) => switch (_amount) {
        'upTo25' => amount <= 25000,
        'from25to50' => amount > 25000 && amount <= 50000,
        'over50' => amount > 50000,
        _ => true,
      };

  bool _matchesFrequency(String frequency) =>
      _frequency == 'all' || frequency == _frequency;

  @override
  Widget build(BuildContext context) {
        final results = catalogTontines
        .where(
          (t) =>
              !t.isPrivate &&
              _matchesAmount(t.amount) &&
              _matchesFrequency(t.frequency),
        )
        .toList();

    return Scaffold(
      appBar: buildAppBar(
        context,
        'Trouver une tontine',
        actions: [
          TextButton.icon(
                        onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinWithCodeScreen()),
            ),
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            label: const Text("J'ai un code"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Des tontines ouvertes à de nouveaux membres. '
            'Tu lis les règles avant de demander à entrer.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TwoColumnGrid(
            children: [
              for (final entry in _amountOptions.entries)
                SelectableCard(
                  compact: true,
                  title: entry.value,
                  selected: _amount == entry.key,
                  onTap: () => setState(() => _amount = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              for (final entry in _frequencyOptions.entries)
                Expanded(
                  child: SelectableCard(
                    compact: true,
                    title: entry.value,
                    selected: _frequency == entry.key,
                    onTap: () => setState(() => _frequency = entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Aucune tontine ne correspond à ces filtres.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          for (final t in results) ...[
            CatalogTontineCard(
              tontine: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TontineDetailScreen(tontine: t),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}