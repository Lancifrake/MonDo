import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/empty_card.dart';

const _pagePadding = EdgeInsets.fromLTRB(24, 8, 24, 24);

class VotesScreen extends StatelessWidget {
  const VotesScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    final r = tontine.rules;

    return Scaffold(
      appBar: buildAppBar(context, 'Les votes'),
      body: ListView(
        padding: _pagePadding,
        children: [
          Text(
            'Présence minimale ${r.voteMinPresencePercent} % · '
            '${r.voteMajority.toLowerCase()}. '
            'Chaque vote dure ${r.voteDurationHours} heures.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const EmptyCard(text: "Aucun vote pour l'instant."),
        ],
      ),
    );
  }
}

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Annonces'),
      body: ListView(
        padding: _pagePadding,
        children: const [
          SizedBox(height: 16),
          EmptyCard(text: "Aucune annonce pour l'instant."),
        ],
      ),
    );
  }
}