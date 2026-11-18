import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';
import 'sign_pin_screen.dart';

class SwapSeatScreen extends StatefulWidget {
  const SwapSeatScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  @override
  State<SwapSeatScreen> createState() => _SwapSeatScreenState();
}

class _SwapSeatScreenState extends State<SwapSeatScreen> {
  int? _selected; // index de la personne choisie dans l'ordre des tours

  Future<void> _sign() async {
    final p = widget.tontine.progress!;
    final myIndex = p.order.indexOf(p.me);
    final other = p.order[_selected!];

    final signed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SignPinScreen(
          title: 'Je signe',
          text: "Tu proposes d'échanger ta place ${myIndex + 1} avec $other "
              '(place ${_selected! + 1}). Cette personne devra aussi signer.',
        ),
      ),
    );

    // Après un « await », on vérifie que l'écran existe toujours
    if (signed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Proposition envoyée à $other')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.tontine.progress!;
    final myIndex = p.order.indexOf(p.me);

    // On ne peut échanger qu'avec quelqu'un qui n'a pas encore reçu
    final candidates = [
      for (var i = 0; i < p.order.length; i++)
        if (i + 1 >= p.currentTurn && i != myIndex) i,
    ];

    return Scaffold(
      appBar: buildAppBar(context, 'Échanger ma place'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          AppCard(
            child: SizedBox(
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'Tu es en position '),
                    TextSpan(
                      text: '${myIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' sur ${p.order.length}. L\'échange demande '
                          "l'accord et la signature des deux personnes.",
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Avec qui veux-tu échanger ?'),
          const SizedBox(height: 10),
          for (final i in candidates) ...[
            _SeatTile(
              position: i + 1,
              name: p.order[i],
              selected: _selected == i,
              onTap: () => setState(() => _selected = i),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: 'Signer et proposer',
            onPressed: _selected == null ? null : _sign,
          ),
        ],
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.position,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final int position;
  final String name;
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
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$position',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}