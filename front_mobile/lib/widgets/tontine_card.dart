import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'status_badge.dart';

class TontineCard extends StatelessWidget {
  const TontineCard({super.key, required this.tontine, this.onTap});

  final Tontine tontine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = tontine;
    final toPay = t.status == PaymentStatus.aPayer;

    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.frequency} · ${t.members}/${t.totalMembers} membres',
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: t.progress,
              minHeight: 6,
              backgroundColor: AppColors.track,
              color: AppColors.green,
            ),
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
              if (t.isTreasurer) ...[
                const StatusBadge(
                  label: 'Trésorier',
                  background: AppColors.blueBg,
                  foreground: AppColors.link,
                ),
                const SizedBox(width: 6),
              ],
              StatusBadge(
                label: toPay ? 'À payer' : 'À jour',
                background: toPay ? AppColors.amberBg : AppColors.mint,
                foreground: toPay ? AppColors.amberText : AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}