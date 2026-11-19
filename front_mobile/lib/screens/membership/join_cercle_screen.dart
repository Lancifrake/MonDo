import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/cercle_des_tours.dart';
import '../../widgets/sobre.dart';
import '../compte/compte_demo_screen.dart';
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

/// Moment où la place reçoit la cagnotte, dit simplement.
String _quand(int place, int membres) => switch (place) {
      1 => 'reçoit en premier',
      _ when place == membres => 'reçoit en dernier',
      _ => 'reçoit au tour $place',
    };

class _JoinState extends ConsumerState<JoinCercleScreen> {
  // Ordre fixé par l'organisateur : la place est écrite dans le règlement, on la signe telle quelle.
  late int _place = widget.cercle.placeFixee ?? widget.cercle.reglement.nombreMembres;
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
    final ordreFixe = c.ordreFixeParOrganisateur == true;
    final nonPrevu = ordreFixe && c.placeFixee == null;
    return Ecran(
      titre: 'Rejoindre',
      enfants: [
        if (identiteManquante)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Bloc(enfants: [
              Ligne(
                'Cette tontine est ouverte à des inconnus : ton identité doit d’abord être vérifiée (niveau 2). '
                'Profil, puis « Vérification d’identité »'
                '${comptesDemoActifs ? ' (en démonstration : « Passer au niveau 2 sans pièce »)' : ''}.',
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
        if (nonPrevu) ...[
          const Titre('Ma place'),
          Bloc(enfants: [
            Ligne(
              'L’organisateur a fixé l’ordre de passage, et tu n’es pas sur sa liste. '
              'Demande-lui de t’ajouter : il lui faut ton identifiant (Profil, « Mon identifiant »).',
              accent: true,
            ),
          ]),
        ] else if (ordreFixe) ...[
          const Titre('Ma place'),
          Center(
            child: CercleDesTours(
              membres: r.nombreMembres,
              maPlace: c.placeFixee,
              taille: 200,
              centre: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Place ${c.placeFixee}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text('fixée par l’organisateur', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Note('Tous les membres signent cet ordre en rejoignant : le score ne le change pas.'),
        ] else ...[
          const Titre('Ma place souhaitée'),
          Note('Touche un point du cercle. Ton score permet les places $premiere à ${r.nombreMembres}. '
              'Recevoir tôt coûte des frais, les dernières places reçoivent une remise. '
              'L’ordre final est fixé quand la tontine est complète.'),
          const SizedBox(height: 12),
          Center(
            // Pour les lecteurs d'écran : glisser vers le haut ou le bas change de place.
            child: Semantics(
              value: 'place $_place sur ${r.nombreMembres}',
              onIncrease: _place < r.nombreMembres ? () => setState(() => _place++) : null,
              onDecrease: _place > premiere ? () => setState(() => _place--) : null,
              child: CercleDesTours(
                membres: r.nombreMembres,
                maPlace: _place,
                premierePlace: premiere,
                taille: 248,
                onPlace: (p) => setState(() => _place = p),
                centre: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Place $_place', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(_quand(_place, r.nombreMembres), style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  // Les frais changent avec la place : on les montre là où l'œil regarde.
                  if (r.bareme.any((f) => f.place == _place)) ...[
                    const SizedBox(height: 6),
                    Text(
                      '+ ${formatAmount(r.bareme.firstWhere((f) => f.place == _place).frais)} FCFA de frais',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.action),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ordreFixe && !nonPrevu && r.bareme.any((f) => f.place == _place))
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
        onPressed: _accepte && !identiteManquante && !nonPrevu ? _rejoindre : null,
      ),
    );
  }
}
