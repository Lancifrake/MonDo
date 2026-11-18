import 'package:flutter/material.dart';
import '../../data/group_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Les rôles'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Tu peux voir les rôles du groupe. '
            'Seuls certains postes peuvent les modifier.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          for (final role in groupRoles) ...[
            _RoleCard(role: role),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role});

  final GroupRole role;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            role.holders,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  color: AppColors.green,
                ),
                Text(
                  '${role.rights.length} droits',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            for (final right in role.rights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        right.label,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: right.afterVote ? 'Après un vote' : 'Oui',
                      background:
                          right.afterVote ? AppColors.amberBg : AppColors.mint,
                      foreground:
                          right.afterVote ? AppColors.amberText : AppColors.green,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}