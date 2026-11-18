import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../data/group_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/rules_format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashed_box.dart';
import '../../widgets/note_box.dart';
import '../../widgets/status_badge.dart';
import 'disputes_screen.dart';
import 'group_parts.dart';
import 'info_screens.dart';
import 'members_screen.dart';
import 'roles_screen.dart';
import 'rules_screen.dart';
import 'swap_seat_screen.dart';
import 'turn_order_screen.dart';

const _grey = Color(0xFFEBEDE7);

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    final t = tontine;
    final p = t.progress;

    return Scaffold(
      appBar: buildAppBar(context, t.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Haut de page : dépend de l'état de la tontine
          if (p == null)
            ..._preparingSections(t)
          else ...[
            RunningSummaryCard(tontine: t, progress: p),
            const SizedBox(height: 16),
            MyContributionCard(tontine: t, progress: p),
          ],
          const SizedBox(height: 28),
          const Text(
            'Tes actions dans ce groupe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: 'Membre',
              background: _grey,
              foreground: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const AppCard(
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Tu es membre : tu peux déclarer tes paiements, les contester, '
                'voir les comptes du groupe et voter.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Le groupe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _GroupList(tontine: t),
          // Bas de page : seulement une fois la tontine démarrée
          if (p != null) ...[
            const SizedBox(height: 28),
            const Text(
              'Qui a payé ce tour',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            PayersCard(progress: p),
            const SizedBox(height: 28),
            const Text(
              'Carnet du groupe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chaque ligne est liée à la précédente : rien ne peut être '
              'changé en silence.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            for (final entry in p.ledger) ...[
              LedgerEntryCard(entry: entry),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  // Haut de page d'une tontine qui n'a pas encore démarré
  List<Widget> _preparingSections(CatalogTontine t) {
    final r = t.rules;

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusBadge(
                  label: 'En préparation',
                  background: AppColors.amberBg,
                  foreground: AppColors.amberText,
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: t.isPrivate ? 'Privée' : 'Ouverte',
                  icon: t.isPrivate ? Icons.lock_outline : Icons.public,
                  background: _grey,
                  foreground: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              t.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      DashedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hourglass_empty, size: 22, color: AppColors.darkGreen),
                SizedBox(width: 8),
                Text(
                  'La tontine démarre bientôt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CheckLine('${t.members} membres sur ${r.minMembers} minimum'),
            const SizedBox(height: 8),
            _CheckLine("L'ordre sera ${orderPhrase(r.orderMode)}"),
            const SizedBox(height: 12),
            const NoteBox(
              "Le président démarre la tontine dès qu'il y a assez de membres.",
            ),
          ],
        ),
      ),
    ];
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupItem {
  const _GroupItem(this.icon, this.title, this.subtitle, this.screen);

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
}

// La liste « Le groupe » : une seule carte, des lignes séparées par un trait
class _GroupList extends StatelessWidget {
  const _GroupList({required this.tontine});

  final CatalogTontine tontine;

  @override
  Widget build(BuildContext context) {
    final t = tontine;

    final items = <_GroupItem>[
      _GroupItem(
        Icons.groups_outlined,
        'Les membres',
        '${t.members} sur ${t.maxMembers}',
        MembersScreen(tontine: t),
      ),
      _GroupItem(
        Icons.description_outlined,
        'Le règlement',
        'Version 1',
        RulesScreen(tontine: t),
      ),
      _GroupItem(
        Icons.shield_outlined,
        'Les rôles',
        '${groupRoles.length} postes',
        const RolesScreen(),
      ),
      _GroupItem(
        Icons.how_to_vote_outlined,
        'Les votes',
        'Aucun en cours',
        VotesScreen(tontine: t),
      ),
      _GroupItem(
        Icons.format_list_numbered,
        "L'ordre des tours",
        t.isRunning ? 'Voir et vérifier le tirage' : 'Fixé au démarrage',
        TurnOrderScreen(tontine: t),
      ),
      _GroupItem(
        Icons.campaign_outlined,
        'Les annonces',
        'Aucune annonce',
        const AnnouncementsScreen(),
      ),
      if (t.isRunning)
        _GroupItem(
          Icons.swap_horiz,
          'Échanger ma place',
          "Avec l'accord d'un autre membre",
          SwapSeatScreen(tontine: t),
        ),
      const _GroupItem(
        Icons.warning_amber_rounded,
        'Un désaccord ?',
        'Signaler un souci',
        DisputesScreen(),
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => items[i].screen),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(items[i].icon, color: AppColors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}