import 'package:flutter/material.dart';
import '../data/catalog_data.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../utils/rules_format.dart';
import 'app_card.dart';
import 'status_badge.dart';

class CatalogTontineCard extends StatelessWidget {
  const CatalogTontineCard({
    super.key,
    required this.tontine,
    required this.onTap,
  });

  final CatalogTontine tontine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tontine;
    final onRequest = t.joinMode == JoinMode.onRequest;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  t.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${t.city} · organisé par ${t.organizer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatAmount(t.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: ' FCFA',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                frequencyLabel(t.frequency),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (t.members / t.maxMembers).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.track,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${t.members} membres sur ${t.maxMembers}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(
                label: onRequest ? 'Sur demande' : 'Entrée libre',
                background: onRequest ? AppColors.amberBg : AppColors.mint,
                foreground: onRequest ? AppColors.amberText : AppColors.green,
              ),
              StatusBadge(
                label: orderLabel(t.rules.orderMode),
                background: const Color(0xFFEBEDE7),
                foreground: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}