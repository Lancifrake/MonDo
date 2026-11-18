import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/payments_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/status_badge.dart';

const _redText = Color(0xFFB3362B);
const _redBg = Color(0xFFFBE3E0);

class PaymentsToValidateScreen extends StatefulWidget {
  const PaymentsToValidateScreen({super.key});

  @override
  State<PaymentsToValidateScreen> createState() =>
      _PaymentsToValidateScreenState();
}

class _PaymentsToValidateScreenState extends State<PaymentsToValidateScreen> {
  int? _refusingId; // paiement dont on est en train de choisir la raison
  String? _reason; // raison choisie

  void _startRefusal(IncomingPayment p) {
    setState(() {
      _refusingId = p.id;
      _reason = null;
    });
  }

  void _cancelRefusal() {
    setState(() {
      _refusingId = null;
      _reason = null;
    });
  }

  void _confirmRefusal(IncomingPayment p) {
    appState.rejectPayment(p, _reason!); // le bouton n'est actif qu'avec une raison
    _cancelRefusal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Paiements à valider'),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final pending = appState.pendingPayments;
          final done = appState.processedPayments;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              const Text(
                'Tu confirmes ou tu refuses chaque paiement. '
                'Un refus demande toujours une raison.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              if (pending.isEmpty)
                const EmptyCard(text: 'Tout est à jour. Aucun paiement en attente.'),
              for (final p in pending) ...[
                _PaymentCard(
                  payment: p,
                  refusing: _refusingId == p.id,
                  reason: _reason,
                  onValidate: () => appState.validatePayment(p),
                  onRefuse: () => _startRefusal(p),
                  onReasonChanged: (value) => setState(() => _reason = value),
                  onCancel: _cancelRefusal,
                  onConfirm: () => _confirmRefusal(p),
                ),
                const SizedBox(height: 12),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Déjà traités',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final p in done) ...[
                  _DoneTile(payment: p),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.refusing,
    required this.reason,
    required this.onValidate,
    required this.onRefuse,
    required this.onReasonChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final IncomingPayment payment;
  final bool refusing; // true = on affiche le choix de la raison
  final String? reason;
  final VoidCallback onValidate;
  final VoidCallback onRefuse;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  // « Référence introuvable » n'a de sens que pour un paiement Mobile Money
  List<String> get _reasons => [
        'Montant incorrect',
        "Je n'ai rien reçu",
        if (payment.reference != null) 'Référence introuvable',
      ];

  Widget _detail() {
    const style = TextStyle(fontSize: 13);
    if (payment.reference != null) {
      return Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Mobile Money · réf. '),
            TextSpan(
              text: payment.reference!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    return Text('Espèces remises à ${payment.receivedBy}', style: style);
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(name: p.payer, index: p.id + 1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.payer,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${p.group} · ${p.when}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatAmount(p.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: ' FCFA',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFE9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _detail(),
          ),
          const SizedBox(height: 12),
          if (refusing) ...[
            const Text(
              'Pourquoi tu refuses ?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final r in _reasons) ...[
              _ReasonTile(
                label: r,
                selected: reason == r,
                onTap: () => onReasonChanged(r),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Annuler',
                    background: Colors.white,
                    foreground: AppColors.textDark,
                    borderColor: AppColors.border,
                    onPressed: onCancel,
                  ),
                ),
                Expanded(
                  child: AppButton(
                    label: 'Confirmer le refus',
                    background: _redBg,
                    foreground: _redText,
                    onPressed: reason == null ? null : onConfirm,
                  ),
                ),
              ],
            ),
          ] else
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Refuser',
                    icon: Icons.close,
                    background: Colors.white,
                    foreground: AppColors.textDark,
                    borderColor: AppColors.border,
                    onPressed: onRefuse,
                  ),
                ),
                Expanded(
                  child: AppButton(
                    label: 'Valider',
                    icon: Icons.check,
                    onPressed: onValidate,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Une raison de refus (case rouge quand elle est choisie)
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _redBg : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _redText : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? _redText : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Une ligne de « Déjà traités »
class _DoneTile extends StatelessWidget {
  const _DoneTile({required this.payment});

  final IncomingPayment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final validated = p.decision == PaymentDecision.validated;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PersonAvatar(name: p.payer, index: p.id + 1, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.payer,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  validated ? p.receiptNumber! : p.rejectReason!,
                  style: TextStyle(
                    fontFamily: validated ? 'monospace' : null,
                    fontSize: validated ? 11 : 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: validated ? 'Validée' : 'Rejetée',
            background: validated ? AppColors.mint : _redBg,
            foreground: validated ? AppColors.green : _redText,
          ),
        ],
      ),
    );
  }
}