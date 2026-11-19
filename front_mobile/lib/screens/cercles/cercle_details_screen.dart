import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../utils/format.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cercle_des_tours.dart';
import '../../widgets/sobre.dart';
import '../membership/join_cercle_screen.dart';
import 'cercles_catalog_screen.dart' show rythme;
import '../compte/compte_demo_screen.dart';
import 'vie_cercle_screens.dart';
import '../../widgets/fond_motif.dart';

/// Fiche d'une tontine : règlement signé, membres, état des cotisations et actions.
/// Les membres et l'ordre ne sont donnés qu'aux membres du cercle.
class CercleDetailsScreen extends ConsumerWidget {
  const CercleDetailsScreen({super.key, required this.cercleId});

  final String cercleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cercle = ref.watch(cercleProvider(cercleId));
    final moi = ref.read(apiClientProvider).membreId ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(cercle.valueOrNull?.nom ?? 'Tontine')),
      body: FondMotif(child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(cercleProvider(cercleId)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: selon(cercle, (c) {
            final membre = c.membres.contains(moi);
            final organisateur = c.organisateurId == moi;
            return [
              _Entete(c: c, moi: moi, membre: membre, organisateur: organisateur),
              const Titre('Règlement signé'),
              _Reglement(r: c.reglement),
              const Titre('Membres'),
              _Membres(c: c, moi: moi),
              if (membre && c.statut != 'en_attente') ...[
                const Titre('Qui a payé'),
                _EtatCotisations(c: c, moi: moi),
              ],
              const SizedBox(height: 20),
              if (membre)
                _ActionsMembre(cercle: c, organisateur: organisateur)
              else if (c.statut == 'en_attente')
                ElevatedButton(
                  onPressed: c.scoreSuffisant == false
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JoinCercleScreen(cercleId: c.id, cercle: c)),
                          ),
                  child: Text(c.scoreSuffisant == false ? 'Score insuffisant pour rejoindre' : 'Rejoindre cette tontine'),
                ),
            ];
          }, reessayer: () => ref.invalidate(cercleProvider(cercleId))),
        ),
      )),
    );
  }
}

/// Tour en cours d'après l'état des paiements : le premier tour pas entièrement confirmé.
int tourDepuisEtat(EtatCotisations e) {
  final tours = [...e.tours]..sort((a, b) => a.numero.compareTo(b.numero));
  if (tours.isEmpty) return 1;
  for (final t in tours) {
    if (t.paiements.isEmpty || t.paiements.any((p) => p.statut != 'confirmee')) return t.numero;
  }
  return tours.last.numero + 1;
}

/// En tête de la fiche : le cercle des tours en grand, puis la cotisation et l'état de la tontine.
class _Entete extends ConsumerWidget {
  const _Entete({required this.c, required this.moi, required this.membre, required this.organisateur});

  final Cercle c;
  final String moi;
  final bool membre;
  final bool organisateur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = c.reglement;
    final n = r.nombreMembres;
    final (statut, ton) = switch (c.statut) {
      'en_attente' => ('cherche des membres', Ton.encre),
      'complet' => ('en cours', Ton.encre),
      'termine' => ('terminée', Ton.gris),
      _ => (c.statut, Ton.gris),
    };
    final inscrits = c.membres.isNotEmpty ? c.membres.length : n - (c.placesRestantes ?? 0);
    final maPlace = c.ordre?.where((o) => o.membreId == moi).firstOrNull?.position;
    // Le tour en cours ne se lit que dans l'état des paiements, réservé aux membres.
    final etat = membre && c.statut == 'complet' ? ref.watch(etatCotisationsCercleProvider(c.id)).valueOrNull : null;
    final tour = switch (c.statut) {
      'termine' => n + 1,
      'en_attente' => 0,
      _ => etat == null ? 0 : tourDepuisEtat(etat),
    };
    final cagnotte = '${formatAmount(r.montant * n)}\u00A0FCFA'; // insécable : le montant ne se coupe pas
    final phrase = switch (c.statut) {
      'en_attente' => n - inscrits <= 1 ? 'Plus qu’une place à prendre' : 'Encore ${n - inscrits} places à prendre',
      'termine' => 'Les $n tours sont joués',
      _ when tour == 0 || maPlace == null => null,
      _ when maPlace == tour => 'C’est ton tour : tu reçois $cagnotte',
      _ when maPlace > tour => maPlace - tour == 1 ? 'Ta cagnotte au prochain tour : $cagnotte' : 'Ta cagnotte dans ${maPlace - tour} tours : $cagnotte',
      _ => 'Tu as reçu ta cagnotte au tour $maPlace',
    };
    final grand = TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.1);
    final petit = TextStyle(fontSize: 13, color: AppColors.textMuted);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        CercleDesTours(
          membres: n,
          tourEnCours: tour,
          maPlace: maPlace,
          // Places prises : seulement avant le départ (sinon les points pleins sont les tours joués).
          inscrits: c.statut == 'en_attente' ? inscrits : null,
          taille: 196,
          centre: switch (tour) {
            0 when c.statut == 'en_attente' => Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$inscrits/$n', style: grand),
                Text('places prises', style: petit),
              ]),
            0 => Text('…', style: grand), // état des paiements en cours de lecture
            _ when tour > n => Icon(Icons.check, size: 36, color: AppColors.vertEncre),
            _ => Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Tour $tour', style: grand),
                Text('sur $n', style: petit),
              ]),
          },
        ),
        if (phrase != null) ...[
          const SizedBox(height: 16),
          Text(
            phrase,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.vertEncre),
          ),
        ],
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        Text('${formatAmount(r.montant)}\u00A0FCFA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text('par membre, ${rythme(r)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Text(
          [statut, if (organisateur) 'tu l’organises' else if (membre) 'tu en es membre', r.ouvert ? 'ouverte' : 'privée'].join(' · '),
          textAlign: TextAlign.center,
          style: styleStatut(ton),
        ),
      ]),
    );
  }
}

class _Reglement extends StatelessWidget {
  const _Reglement({required this.r});

  final Reglement r;

  @override
  Widget build(BuildContext context) => Bloc(enfants: [
        Ligne('Membres', valeur: '${r.nombreMembres}'),
        Ligne('Cagnotte reçue à son tour', valeur: '${formatAmount(r.montant * r.nombreMembres)} FCFA'),
        Ligne('Premier tour', valeur: formatDate(r.datePremierTour)),
        Ligne('Délai de grâce', valeur: '${r.delaiGraceJours} jour(s)'),
        Ligne('Pénalité de retard', valeur: '${formatAmount(r.penaliteRetard)} FCFA'),
        if (r.scoreMinimum != null) Ligne('Score minimum', valeur: '${r.scoreMinimum}'),
        if (r.bareme.isNotEmpty)
          Ligne(
            'Frais des premières places',
            valeur: r.bareme.map((f) => '${f.place} : ${formatAmount(f.frais)}').join(' · '),
          ),
      ]);
}

class _Membres extends StatelessWidget {
  const _Membres({required this.c, required this.moi});

  final Cercle c;
  final String moi;

  @override
  Widget build(BuildContext context) {
    final ordre = [...?c.ordre]..sort((a, b) => a.position.compareTo(b.position));
    final inscrits = c.membres.isNotEmpty ? c.membres.length : c.reglement.nombreMembres - (c.placesRestantes ?? 0);
    return Bloc(enfants: [
      Ligne('Inscrits', valeur: '$inscrits sur ${c.reglement.nombreMembres}'),
      for (final o in ordre)
        Ligne(
          'Place ${o.position}${o.membreId == moi ? ' · moi' : ''}${o.membreId == c.organisateurId ? ' · organisateur' : ''}',
        ),
      if (ordre.isEmpty)
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('L’ordre de passage est fixé quand toutes les places sont prises.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
    ]);
  }
}

class _EtatCotisations extends ConsumerWidget {
  const _EtatCotisations({required this.c, required this.moi});

  final Cercle c;
  final String moi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(etatCotisationsCercleProvider(c.id));
    return Column(
      children: selon(etat, (e) => [
            for (var i = 0; i < e.tours.length; i++) ...[
              if (i > 0) const TraitRangee(marge: 0),
              () {
                final t = e.tours[i];
                final payes = t.paiements.where((p) => p.statut == 'confirmee').length;
                final retard = t.paiements.where((p) => p.enRetard).length;
                final complet = payes == t.paiements.length && t.paiements.isNotEmpty;
                return RangeeIcone(
                  marge: 0,
                  icone: retard > 0 ? Icons.schedule : (complet ? Icons.check_circle_outline : Icons.hourglass_empty),
                  couleurIcone: retard > 0 ? AppColors.action : (complet ? AppColors.green : AppColors.textMuted),
                  titre: 'Tour ${t.numero}',
                  detail: 'Reçoit ${membreLibelle(c, t.beneficiaireId, moi).toLowerCase()}',
                  valeur: retard > 0 ? '$payes/${t.paiements.length} payés · $retard en retard' : '$payes/${t.paiements.length} payés',
                  accent: retard > 0,
                );
              }(),
            ],
          ]),
    );
  }
}

/// Actions d'un membre : vie de la tontine, invitation, démonstration, départ, nouveau cycle.
class _ActionsMembre extends ConsumerWidget {
  const _ActionsMembre({required this.cercle, required this.organisateur});

  final Cercle cercle;
  final bool organisateur;

  Future<void> _faire(BuildContext context, WidgetRef ref, Future<Object?> Function() action, String ok) async {
    try {
      await action();
      ref.invalidate(cercleProvider(cercle.id));
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(mesCotisationsRefreshableProvider);
      ref.invalidate(etatCotisationsCercleProvider(cercle.id));
      if (context.mounted) afficherMessage(context, ok);
    } catch (e) {
      if (context.mounted) afficherErreur(context, e);
    }
  }

  Future<void> _inviter(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final numero = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inviter par numéro'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(prefixText: '+237 ', hintText: '6 99 42 18 06'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, '+237${ctrl.text.replaceAll(' ', '')}'), child: const Text('Envoyer le SMS')),
        ],
      ),
    );
    if (numero == null || !context.mounted) return;
    await _faire(
      context,
      ref,
      () => ref.read(cerclesServiceProvider).inviterMembre(cercleId: cercle.id, numeroTelephone: numero),
      'Invitation envoyée par SMS.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(cerclesServiceProvider);
    final espace = ref.read(espaceServiceProvider);
    void ouvrir(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    final enCours = cercle.statut == 'complet';
    final autres = [...?cercle.ordre]..sort((a, b) => a.position.compareTo(b.position));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 1, color: AppColors.border),
        RangeeIcone(
          marge: 0,
          icone: Icons.receipt_long_outlined,
          titre: 'Registre et preuve d’intégrité',
          detail: 'Chaque paiement et engagement, inscrit et vérifiable',
          onTap: () => ouvrir(RegistreScreen(cercleId: cercle.id)),
        ),
        if (enCours) ...[
          const TraitRangee(marge: 0),
          RangeeIcone(
            marge: 0,
            icone: Icons.swap_horiz,
            titre: 'Échanges de places',
            onTap: () => ouvrir(EchangesScreen(cercle: cercle)),
          ),
        ],
        if (organisateur) ...[
          const TraitRangee(marge: 0),
          RangeeIcone(
            marge: 0,
            icone: Icons.smart_toy_outlined,
            titre: 'Assistant de l’organisateur',
            detail: 'Rappels, relances et mises en demeure',
            onTap: () => ouvrir(AssistantScreen(cercle: cercle)),
          ),
        ],
        Divider(height: 1, thickness: 1, color: AppColors.border),
        if (enCours && autres.isNotEmpty) ...[
          const Titre('Dossier de preuve d’un membre en défaut'),
          for (final o in autres.where((o) => o.membreId != espace.moi))
            RangeeIcone(
              marge: 0,
              icone: Icons.folder_outlined,
              titre: 'Place ${o.position}',
              onTap: () => ouvrir(DossierPreuveScreen(cercle: cercle, membreId: o.membreId)),
            ),
        ],
        const SizedBox(height: 20),
        if (organisateur && cercle.statut == 'en_attente') ...[
          ElevatedButton(onPressed: () => _inviter(context, ref), child: const Text('Inviter un membre')),
          if (comptesDemoActifs) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _faire(context, ref, () => service.demoMembresFictifs(cercle.id), 'Tontine complétée avec des membres fictifs.'),
              child: const Text('Démo : remplir avec des fictifs'),
            ),
          ],
        ],
        if (enCours) ...[
          if (comptesDemoActifs) ...[
            OutlinedButton(
              onPressed: () => _faire(context, ref, () => service.demoSuite(cercle.id), 'Les membres fictifs ont joué le tour en cours.'),
              child: const Text('Démo : les autres jouent le tour'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _faire(context, ref, () => espace.demoAvancer(cercle.id, 10), 'Le temps a avancé de 10 jours.'),
              child: const Text('Démo : avancer de 10 jours'),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Quitter la tontine ?'),
                  content: const Text(
                    'Possible seulement avant d’avoir reçu. Ce que tu as versé te sera remboursé selon le règlement, '
                    'et le départ est inscrit au registre.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Quitter', style: TextStyle(color: AppColors.rouge)),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await _faire(context, ref, () => espace.quitter(cercle.id), 'Tu as quitté la tontine.');
              }
            },
            child: Text('Quitter la tontine', style: TextStyle(color: AppColors.rouge)),
          ),
        ],
        if (organisateur && cercle.statut == 'termine')
          ElevatedButton(
            onPressed: () {
              final r = cercle.reglement;
              _faire(
                context,
                ref,
                () => service.createCercle(
                  montant: r.montant,
                  frequence: r.frequence,
                  periodeJours: r.periodeJours,
                  nombreMembres: r.nombreMembres,
                  ouvert: r.ouvert,
                  datePremierTour: DateTime.now().add(const Duration(days: 7)),
                  penaliteRetard: r.penaliteRetard,
                  delaiGraceJours: r.delaiGraceJours,
                  scoreMinimum: r.scoreMinimum,
                  cerclePrecedentId: cercle.id,
                ),
                'Nouveau cycle créé : les anciens membres sont invités à signer de nouveau.',
              );
            },
            child: const Text('Relancer un nouveau cycle'),
          ),
      ],
    );
  }
}
