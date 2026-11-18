import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/counter_row.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';

/// Étape 2 : qui peut rejoindre, combien chacun cotise, combien de membres.
class InfoStep extends StatefulWidget {
  const InfoStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged;

  @override
  State<InfoStep> createState() => _InfoStepState();
}

class _InfoStepState extends State<InfoStep> {
  TontineDraft get d => widget.draft;
  late final _montantCtrl = TextEditingController(text: '${widget.draft.montant}');

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    change();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Combien chacun cotise à chaque tour ?'),
        const SizedBox(height: 8),
        TextField(
          controller: _montantCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _update(() => d.montant = int.tryParse(v) ?? 0),
          decoration: const InputDecoration(hintText: '10000', suffixText: 'FCFA'),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Combien de membres ?'),
        const SizedBox(height: 10),
        CounterRow(
          label: 'Membres',
          value: d.nombreMembres,
          onMinus: d.nombreMembres > 3 ? () => _update(() => d.nombreMembres--) : null,
          onPlus: d.nombreMembres < 50 ? () => _update(() => d.nombreMembres++) : null,
        ),
        const SizedBox(height: 10),
        const Text(
          'La tontine démarre quand toutes les places sont prises. Un tour par membre.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Qui peut trouver et rejoindre ta tontine ?'),
        const SizedBox(height: 10),
        SelectableCard(
          title: 'Privée',
          subtitle: 'Seulement les personnes que tu invites par leur numéro',
          selected: d.isPrivate,
          onTap: () => _update(() => d.isPrivate = true),
        ),
        const SizedBox(height: 10),
        SelectableCard(
          title: "Ouverte à d'autres personnes",
          subtitle: 'Elle apparaît dans le catalogue : des inconnus peuvent la rejoindre selon leur score',
          selected: !d.isPrivate,
          onTap: () => _update(() => d.isPrivate = false),
        ),
      ],
    );
  }
}
