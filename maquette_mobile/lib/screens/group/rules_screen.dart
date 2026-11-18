import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/note_box.dart';
import '../../widgets/rule_cards.dart';
import '../../widgets/status_badge.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Le règlement'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: 'Version 1',
              background: AppColors.blueBg,
              foreground: AppColors.link,
            ),
          ),
          const SizedBox(height: 12),
          RuleCards(rules: tontine.rules),
          const SizedBox(height: 16),
          const NoteBox(
            'Seuls certains postes peuvent changer le règlement. '
            'Tu peux proposer un vote si ton rôle le permet.',
          ),
        ],
      ),
    );
  }
}