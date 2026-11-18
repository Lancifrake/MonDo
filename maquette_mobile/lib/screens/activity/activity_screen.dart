import 'package:flutter/material.dart';
import '../../data/activity_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import 'receipt_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const Text(
            'Mon activité',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toutes tes opérations, claires et infalsifiables.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          for (final item in activityItems) ...[
            _ActivityCard(item: item),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final isPayout = item.kind == ActivityKind.payout;
    final isIncoming = item.amount > 0;
    final receipt = item.receipt;
    final amountText =
        '${isIncoming ? '+' : '−'} ${formatAmount(item.amount.abs())} F';

    return AppCard(
      // Seule une cotisation a un reçu à ouvrir
      onTap: receipt == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceiptScreen(receipt: receipt),
                ),
              ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPayout ? const Color(0xFFE6E0F5) : AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPayout ? Icons.south_west : Icons.check,
              size: 20,
              color: isPayout ? const Color(0xFF6C5BA8) : AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isIncoming ? AppColors.green : AppColors.textDark,
            ),
          ),
          if (receipt != null)
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}