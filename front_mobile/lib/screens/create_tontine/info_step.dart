import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/counter_row.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/switch_card.dart';

class InfoStep extends StatefulWidget {
  const InfoStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged;

  @override
  State<InfoStep> createState() => _InfoStepState();
}

class _InfoStepState extends State<InfoStep> {
  // On remplit les champs avec le brouillon : si l'utilisateur revient
  // sur cette étape, il retrouve ce qu'il avait écrit.
  late final _nameCtrl = TextEditingController(text: widget.draft.name);
  late final _descCtrl = TextEditingController(text: widget.draft.description);

  TontineDraft get d => widget.draft;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Applique un changement au brouillon puis prévient l'écran parent
  void _update(VoidCallback change) {
    change();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Nom de ta tontine'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => _update(() => d.name = value),
          decoration: const InputDecoration(
            hintText: 'Ex. Les Bâtisseurs de Bonamoussadi',
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('En quelques mots (facultatif)'),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => _update(() => d.description = value),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Qui peut trouver et rejoindre ta tontine ?'),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Privée',
          subtitle:
              'Seulement les personnes que tu invites (lien, QR code ou numéro)',
          selected: d.isPrivate,
          onTap: () => _update(() => d.isPrivate = true),
        ),
        const SizedBox(height: 10),
        SelectableCard(
          title: "Ouverte à d'autres personnes",
          subtitle:
              "Elle apparaît dans le catalogue : des inconnus peuvent demander à rejoindre",
          selected: !d.isPrivate,
          onTap: () => _update(() => d.isPrivate = false),
        ),
        const SizedBox(height: 16),
        SwitchCard(
          title: 'Je valide chaque nouveau membre',
          subtitle: 'Sinon, les personnes invitées entrent directement.',
          value: d.validateMembers,
          onChanged: (value) => _update(() => d.validateMembers = value),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Combien de personnes ?'),
        const SizedBox(height: 10),
        CounterRow(
          label: 'Au minimum',
          value: d.minMembers,
          onMinus: d.minMembers > 2 ? () => _update(() => d.minMembers--) : null,
          onPlus: d.minMembers < d.maxMembers
              ? () => _update(() => d.minMembers++)
              : null,
        ),
        const SizedBox(height: 10),
        CounterRow(
          label: 'Au maximum',
          value: d.maxMembers,
          onMinus: d.maxMembers > d.minMembers
              ? () => _update(() => d.maxMembers--)
              : null,
          onPlus: d.maxMembers < 50 ? () => _update(() => d.maxMembers++) : null,
        ),
        const SizedBox(height: 10),
        const Text(
          'La tontine démarre quand le minimum est atteint.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}