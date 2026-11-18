import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/payments_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/note_box.dart';
import '../../widgets/section_label.dart';
import '../../widgets/two_column_grid.dart';
import 'declaration_sent_screen.dart';

class DeclarePaymentScreen extends StatefulWidget {
  const DeclarePaymentScreen({super.key, required this.due});

  final DueContribution due;

  @override
  State<DeclarePaymentScreen> createState() => _DeclarePaymentScreenState();
}

class _DeclarePaymentScreenState extends State<DeclarePaymentScreen> {
  PayMode _mode = PayMode.mobileMoney;
  final _refCtrl = TextEditingController();

  // Mobile Money : il faut la référence. Espèces : rien d'autre à remplir.
  bool get _canSend =>
      _mode == PayMode.cash || _refCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final due = widget.due;
    final declaration = Declaration(
      group: due.group,
      turn: due.turn,
      amount: due.amount,
      mode: _mode,
      payer: 'Amina N.',
      reference: _mode == PayMode.mobileMoney
          ? _refCtrl.text.trim().toUpperCase()
          : null,
    );

    appState.declarePayment(declaration); // l'accueil se met à jour

    // pushReplacement : le retour ne ramène pas au formulaire déjà envoyé
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeclarationSentScreen(declaration: declaration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.due;

    return Scaffold(
      appBar: buildAppBar(context, 'Déclarer mon paiement'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                due.group,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cotisation du tour ${due.turn}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatAmount(due.amount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'FCFA',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        const TextSpan(text: 'À envoyer ou remettre à '),
                        TextSpan(
                          text: due.collector,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const TextSpan(text: ', trésorier du groupe.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Mode de paiement'),
                  const SizedBox(height: 10),
                  TwoColumnGrid(
                    children: [
                      _ModeCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Mobile Money',
                        subtitle: 'Déjà payé depuis ton téléphone',
                        selected: _mode == PayMode.mobileMoney,
                        onTap: () => setState(() => _mode = PayMode.mobileMoney),
                      ),
                      _ModeCard(
                        icon: Icons.payments_outlined,
                        title: 'Espèces',
                        subtitle: 'Remis en main propre',
                        selected: _mode == PayMode.cash,
                        onTap: () => setState(() => _mode = PayMode.cash),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_mode == PayMode.mobileMoney) ...[
                    const SectionLabel('Référence de la transaction'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _refCtrl,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Ex. MP2406180938',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tu la trouves dans le SMS de confirmation de ton opérateur.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ] else
                    const NoteBox(
                      'La personne qui encaisse confirmera la réception de '
                      "l'argent dans l'application.",
                    ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: 'Envoyer la déclaration',
              onPressed: _canSend ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.green : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.green : AppColors.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}