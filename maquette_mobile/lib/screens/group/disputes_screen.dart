import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_card.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/status_badge.dart';

class _Dispute {
  const _Dispute(this.category, this.text);

  final String category;
  final String text;
}

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  static const _categories = [
    'Un paiement',
    "Le comportement d'un membre",
    'Un compte bloqué',
  ];

  final _textCtrl = TextEditingController();
  final _disputes = <_Dispute>[];
  bool _formOpen = false;
  String _category = _categories.first;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _closeForm() {
    setState(() {
      _formOpen = false;
      _textCtrl.clear();
      _category = _categories.first;
    });
  }

  void _send() {
    final dispute = _Dispute(_category, _textCtrl.text.trim());
    setState(() => _disputes.insert(0, dispute));
    _closeForm();
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in _categories) ...[
            SelectableCard(
              compact: true,
              title: category,
              selected: _category == category,
              onTap: () => setState(() => _category = category),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          const SectionLabel('Explique en une phrase'),
          const SizedBox(height: 8),
          TextField(
            controller: _textCtrl,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: AppButton(
                  label: 'Annuler',
                  background: Colors.white,
                  foreground: AppColors.textDark,
                  borderColor: AppColors.border,
                  onPressed: _closeForm,
                ),
              ),
              Expanded(
                child: AppButton(
                  label: 'Envoyer',
                  onPressed: _textCtrl.text.trim().isEmpty ? null : _send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        'Désaccords',
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _formOpen = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Signaler'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            "Un souci avec un paiement ou un membre ? Signale-le : une personne "
            "du groupe va t'aider d'abord.",
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.link),
          ),
          const SizedBox(height: 16),
          if (_formOpen) ...[_buildForm(), const SizedBox(height: 16)],
          if (_disputes.isEmpty && !_formOpen)
            const EmptyCard(text: 'Aucun désaccord. Tout va bien.'),
          for (final dispute in _disputes) ...[
            AppCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dispute.category,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const StatusBadge(
                          label: 'Signalé',
                          background: AppColors.amberBg,
                          foreground: AppColors.amberText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dispute.text,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}