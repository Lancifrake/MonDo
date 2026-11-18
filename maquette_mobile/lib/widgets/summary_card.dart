import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class SummaryRow {
  const SummaryRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor; // couleur spéciale pour la valeur (facultatif)
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, this.title, required this.rows});

  final String? title; // pas de titre pour la première carte du résumé
  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
          ],
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _RowView(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _RowView extends StatelessWidget {
  const _RowView({required this.row});

  final SummaryRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            row.label,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: row.valueColor ?? AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}