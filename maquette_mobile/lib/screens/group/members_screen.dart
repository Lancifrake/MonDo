import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../data/group_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/status_badge.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    final progress = tontine.progress;
    final members =
        progress?.order ?? demoMembers.take(tontine.members).toList();

    return Scaffold(
      appBar: buildAppBar(
        context,
        'Membres (${members.length}/${tontine.maxMembers})',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Tous les membres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < members.length; i++) ...[
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PersonAvatar(name: members[i], index: i),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          members[i],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Le président n'est connu que pour une tontine
                        // en préparation (données de démonstration)
                        if (progress == null && i == 0) ...[
                          const SizedBox(height: 4),
                          const StatusBadge(
                            label: 'Président',
                            background: AppColors.mint,
                            foreground: AppColors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}