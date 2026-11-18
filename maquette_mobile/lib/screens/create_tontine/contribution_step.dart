import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/counter_row.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/switch_card.dart';
import '../../widgets/two_column_grid.dart';

const _weekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

const _frequencies = {
  'weekly': 'Chaque semaine',
  'biweekly': '2 semaines',
  'monthly': 'Chaque mois',
  'other': 'Autre rythme',
};

final _hours = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');

class ContributionStep extends StatefulWidget {
  const ContributionStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TontineDraft draft;
  final VoidCallback onChanged;

  @override
  State<ContributionStep> createState() => _ContributionStepState();
}

class _ContributionStepState extends State<ContributionStep> {
  late final _amountCtrl = TextEditingController(
    text: widget.draft.amount > 0 ? formatAmount(widget.draft.amount) : '',
  );

  TontineDraft get d => widget.draft;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    change();
    widget.onChanged();
  }

  void _setAmount(int value) {
    _amountCtrl.text = formatAmount(value);
    _update(() => d.amount = value);
  }

  Widget _deadlineRow() {
    if (d.frequency == 'monthly') {
      return CounterRow(
        label: 'Date limite : le',
        valueText: '${d.deadlineDay} du mois',
        onMinus: d.deadlineDay > 1 ? () => _update(() => d.deadlineDay--) : null,
        onPlus: d.deadlineDay < 28 ? () => _update(() => d.deadlineDay++) : null,
      );
    }
    // Rythme hebdomadaire : on choisit un jour de la semaine
    return CounterRow(
      label: 'Jour limite :',
      valueText: _weekdays[d.deadlineWeekday],
      onMinus: () =>
          _update(() => d.deadlineWeekday = (d.deadlineWeekday + 6) % 7),
      onPlus: () =>
          _update(() => d.deadlineWeekday = (d.deadlineWeekday + 1) % 7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Combien chacun cotise ?'),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          onChanged: (value) {
            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            _update(() => d.amount = int.tryParse(digits) ?? 0);
          },
          decoration: const InputDecoration(
            hintText: '0',
            suffix: Text(
              'FCFA',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Minimum 500 FCFA',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in const [10000, 20000, 50000, 100000])
              _AmountChip(
                label: '${formatAmount(value)} F',
                onTap: () => _setAmount(value),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SwitchCard(
          title: 'Un membre peut prendre plusieurs parts',
          subtitle: 'Il cotise davantage, et reçoit davantage.',
          value: d.multiParts,
          onChanged: (value) => _update(() => d.multiParts = value),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Tous les combien ?'),
        const SizedBox(height: 10),
        TwoColumnGrid(
          children: [
            for (final entry in _frequencies.entries)
              SelectableCard(
                compact: true,
                title: entry.value,
                selected: d.frequency == entry.key,
                onTap: () => _update(() => d.frequency = entry.key),
              ),
          ],
        ),
        if (d.frequency != 'other') ...[
          const SizedBox(height: 12),
          _deadlineRow(),
        ],
        const SizedBox(height: 24),
        const SectionLabel('Heure limite'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: d.deadlineHour,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              borderRadius: BorderRadius.circular(14),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontWeight: FontWeight.w600),
              items: [
                for (final hour in _hours)
                  DropdownMenuItem(value: hour, child: Text(hour)),
              ],
              onChanged: (value) {
                if (value != null) _update(() => d.deadlineHour = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}