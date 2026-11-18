import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../utils/rules_format.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/check_card.dart';
import '../../widgets/rule_cards.dart';
import '../../widgets/status_badge.dart';
import '../profile/offers_screen.dart';
import 'commit_pin_screen.dart';

class TontineDetailScreen extends StatefulWidget {
  const TontineDetailScreen({
    super.key,
    required this.tontine,
    this.invited = false,
  });

  final CatalogTontine tontine;
  final bool invited; // true = on arrive avec un code d'invitation

  @override
  State<TontineDetailScreen> createState() => _TontineDetailScreenState();
}

class _TontineDetailScreenState extends State<TontineDetailScreen> {
  bool _accepted = false; // case « J'ai lu le règlement... »

  void _join() {
    // On confirme d'abord avec le code PIN (écran « Je m'engage »)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommitPinScreen(tontine: widget.tontine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tontine;
    final onRequest = t.joinMode == JoinMode.onRequest;

    return Scaffold(
      appBar: buildAppBar(context, 'Fiche de la tontine'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${t.city} · organisé par ${t.organizer}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (t.isPrivate)
                        const StatusBadge(
                          label: 'Privée',
                          background: AppColors.mint,
                          foreground: AppColors.green,
                        )
                      else
                        const StatusBadge(
                          label: 'Ouverte',
                          background: AppColors.blueBg,
                          foreground: AppColors.link,
                        ),
                      StatusBadge(
                        label: onRequest ? 'Sur demande' : 'Entrée libre',
                        background:
                            onRequest ? AppColors.amberBg : AppColors.mint,
                        foreground:
                            onRequest ? AppColors.amberText : AppColors.green,
                      ),
                      StatusBadge(
                        label: '${t.members} / ${t.maxMembers} membres',
                        background: const Color(0xFFEBEDE7),
                        foreground: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.description,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  if (widget.invited) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tu as été invité dans cette tontine.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _CommitmentCard(rules: t.rules),
                  const SizedBox(height: 20),
                  RuleCards(rules: t.rules),
                  const SizedBox(height: 16),
                  const _PremiumBanner(),
                  const SizedBox(height: 16),
                  CheckCard(
                    label: "J'ai lu le règlement et j'accepte de le respecter.",
                    checked: _accepted,
                    onChanged: (value) => setState(() => _accepted = value),
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: 'Rejoindre',
              onPressed: _accepted ? _join : null,
            ),
          ),
        ],
      ),
    );
  }
}

// L'encadré vert « Ce que tu t'engages à faire »
class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.rules});

  final TontineDraft rules;

  @override
  Widget build(BuildContext context) {
    final deadline = deadlinePhrase(rules);
    final deadlineText =
        deadline == null ? '' : ', au plus tard $deadline à ${rules.deadlineHour}';

    final items = [
      'Payer ${fcfa(rules.amount)} ${frequencyPhrase(rules.frequency)}'
          '$deadlineText.',
      latePhrase(rules),
      "Accepter l'ordre des tours ${orderPhrase(rules.orderMode)}.",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ce que tu t'engages à faire",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.lime,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// La bannière jaune « Premium »
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E0A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.amberText,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Avec l'offre Premium, tu peux gérer 5 tontines.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Gérer plus de tontines ou de membres demande plus de gestion.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tes données restent toutes accessibles : rien n'est jamais "
            'supprimé ni caché.',
            style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersScreen()),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Voir les offres'),
            ),
          ),
        ],
      ),
    );
  }
}