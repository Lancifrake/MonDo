import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';
import '../cercles/cercles_catalog_screen.dart' show rythme;

/// Rejoindre une tontine : le membre choisit sa place souhaitée et SIGNE son engagement,
/// qui reprend l'empreinte du règlement. Le serveur fixe l'ordre quand la tontine est complète.
class JoinCercleScreen extends ConsumerStatefulWidget {
  const JoinCercleScreen({super.key, required this.cercleId, required this.cercle});

  final String cercleId;
  final Cercle cercle;

  @override
  ConsumerState<JoinCercleScreen> createState() => _JoinState();
}

class _JoinState extends ConsumerState<JoinCercleScreen> {
  late int _place = widget.cercle.reglement.nombreMembres;
  bool _accepte = false;
  bool _envoi = false;

  Future<void> _rejoindre() async {
    setState(() => _envoi = true);
    try {
      await ref.read(cerclesServiceProvider).adhererAuCercle(cercle: widget.cercle, placeSouhaitee: _place);
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(cercleProvider(widget.cercleId));
      if (!mounted) return;
      afficherMessage(context, 'Tu as rejoint la tontine. Ton engagement est signé.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cercle;
    final r = c.reglement;
    final premiere = c.premierePlaceAutorisee ?? 1;
    final niveau = ref.watch(authStateProvider).compte?.niveau ?? 1;
    final identiteManquante = r.ouvert && niveau < 2;
    return Ecran(
      titre: 'Rejoindre',
      enfants: [
        if (identiteManquante)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Bloc(enfants: [
              Ligne(
                'Cette tontine est ouverte à des inconnus : ton identité doit d’abord être vérifiée (niveau 2). '
                'Profil, puis « Vérification d’identité » (en démonstration : « Passer au niveau 2 sans pièce »).',
                accent: true,
              ),
            ]),
          ),
        Bloc(enfants: [
          Ligne('Cotisation', valeur: '${formatAmount(r.montant)} FCFA, ${rythme(r)}'),
          Ligne('Cagnotte à ton tour', valeur: '${formatAmount(r.montant * r.nombreMembres)} FCFA'),
          Ligne('Premier tour', valeur: formatDate(r.datePremierTour)),
          Ligne('Retard', valeur: '${r.delaiGraceJours} j de grâce, puis ${formatAmount(r.penaliteRetard)} FCFA'),
        ]),
        const Titre('Ma place souhaitée'),
        Note('Ton score permet les places $premiere à ${r.nombreMembres}. Recevoir tôt coûte des frais, '
            'les dernières places reçoivent une remise. L’ordre final est fixé quand la tontine est complète.'),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var p = 1; p <= r.nombreMembres; p++)
            ChoiceChip(
              label: Text('$p', style: TextStyle(color: p == _place ? Colors.white : (p < premiere ? AppColors.textMuted : AppColors.textDark))),
              selected: p == _place,
              onSelected: p < premiere ? null : (_) => setState(() => _place = p),
            ),
        ]),
        if (r.bareme.any((f) => f.place == _place))
          Note('Frais pour la place $_place : ${formatAmount(r.bareme.firstWhere((f) => f.place == _place).frais)} FCFA.'),
        const Titre('Engagement'),
        CheckboxListTile(
          value: _accepte,
          onChanged: (v) => setState(() => _accepte = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Je m’engage à cotiser à chaque tour jusqu’à la fin du cycle. Mon engagement est signé et inscrit au registre.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
      bas: AppButton(
        label: 'Signer et rejoindre',
        isLoading: _envoi,
        onPressed: _accepte && !identiteManquante ? _rejoindre : null,
      ),
    );
  }
}
