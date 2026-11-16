import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/switch_card.dart';

class ModelStep extends StatelessWidget {
  const ModelStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged; // prévient l'écran parent qu'il faut se redessiner

  static const _soon = [
    'Caisse pour un projet',
    "Entraide en cas d'événement",
    'Enchères',
    'Prêts entre membres',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Type de tontine'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _TypeChip(label: 'Tontine classique', selected: true),
            for (final label in _soon) _TypeChip(label: '$label · bientôt'),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Choisis un modèle : les règles sont déjà prêtes'),
        const SizedBox(height: 12),
        for (final m in tontineModels) ...[
          SelectableCard(
            title: m.title,
            subtitle: m.description,
            selected: draft.model == m.id,
            showCheck: true,
            onTap: () {
              draft.model = m.id;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
        ],
        SwitchCard(
          title: 'Je veux tout régler moi-même',
          subtitle:
              'Ajoute deux étapes : retards et impayés, argent liquide et décisions.',
          value: draft.customAll,
          onChanged: (value) {
            draft.customAll = value;
            onChanged();
          },
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
        color: selected ? AppColors.green : const Color(0xFFEBEDE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}