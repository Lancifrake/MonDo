import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';

class ModelStep extends StatelessWidget {
  const ModelStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged; // prévient l'écran parent qu'il faut se redessiner

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Choisis un modèle : les règles sont déjà prêtes'),
        const SizedBox(height: 12),
        for (final m in tontineModels) ...[
          SelectableCard(
            title: m.title,
            subtitle: m.description,
            selected: draft.model == m.id,
            showCheck: true,
            onTap: () {
              draft.appliquerModele(m.id);
              onChanged();
            },
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Le modèle pré-remplit le montant et le rythme : tu pourras tout changer aux étapes suivantes.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.textDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.surface : AppColors.textMuted,
        ),
      ),
    );
  }
}