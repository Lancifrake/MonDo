import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/sobre.dart';
import '../compte/compte_demo_screen.dart' show comptesDemoActifs;
import '../cercles/vie_cercle_screens.dart';
import 'payment_declare_screen.dart';
import '../../widgets/fond_motif.dart';

/// Mes cotisations dans toutes mes tontines : ce que je dois et ce qu'on me doit.
/// Le payeur déclare, le bénéficiaire confirme ; MonDo ne touche jamais l'argent.
class CotisationsListScreen extends ConsumerStatefulWidget {
  const CotisationsListScreen({super.key});

  @override
  ConsumerState<CotisationsListScreen> createState() => _CotisationsState();
}

class _CotisationsState extends ConsumerState<CotisationsListScreen> {
  String _filtre = 'action';

  @override
  Widget build(BuildContext context) {
    final moi = ref.read(apiClientProvider).membreId;
    final cotisations = ref.watch(mesCotisationsRefreshableProvider);
    final noms = {for (final c in ref.watch(mesCerclesRefreshableProvider).valueOrNull ?? const <ResumeCercle>[]) c.id: c.nom};

    bool aFaire(Cotisation c) =>
        (c.payeurId == moi && c.statut == 'due') || (c.beneficiaireId == moi && c.statut == 'declaree');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cotisations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: FondMotif(child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mesCotisationsRefreshableProvider),
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Filtres(
                choix: const {'action': 'À faire', 'due': 'Dues', 'declaree': 'Déclarées', 'confirmee': 'Confirmées'},
                actif: _filtre,
                onChange: (v) => setState(() => _filtre = v),
              ),
            ),
            const SizedBox(height: 8),
            ...selon(cotisations, (liste) {
              final vues = liste.where((c) => _filtre == 'action' ? aFaire(c) : c.statut == _filtre).toList();
              if (vues.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Note(_filtre == 'action' ? 'Rien à faire pour l’instant.' : 'Aucune cotisation ici.'),
                  ),
                ];
              }
              // Les plus récentes d'abord ; au-delà de 10, « Tout voir ».
              vues.sort((a, b) => b.dateLimite.compareTo(a.dateLimite));
              return [
                ListeLimitee(
                  key: ValueKey(_filtre),
                  nombre: vues.length,
                  separateur: const TraitRangee(),
                  construire: (i) => _Cotisation(c: vues[i], moi: moi, nomCercle: noms[vues[i].cercleId]),
                ),
              ];
            }, reessayer: () => ref.invalidate(mesCotisationsRefreshableProvider), marge: Espace.ecran),
          ],
        ),
      )),
    );
  }
}

class _Cotisation extends ConsumerWidget {
  const _Cotisation({required this.c, required this.moi, this.nomCercle});

  final Cotisation c;
  final String? moi;
  final String? nomCercle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeDois = c.payeurId == moi;
    final aFaire = (c.statut == 'due' && jeDois) || (c.statut == 'declaree' && !jeDois);
    final statut = switch (c.statut) {
      'due' when jeDois => 'À payer',
      'due' => 'Attendue',
      'declaree' when !jeDois => 'Déclarée, à confirmer',
      'declaree' => 'Déclarée, en attente de confirmation',
      'confirmee' => 'Confirmée',
      'annulee' => 'Annulée',
      final x => x,
    };
    final couleur = aFaire
        ? AppColors.action
        : c.statut == 'confirmee'
            ? AppColors.green
            : AppColors.textMuted;
    final details = [
      ?nomCercle,
      statut,
      'avant le ${formatDate(c.dateLimite)}',
      if (c.penaliteDue > 0) 'pénalité ${formatAmount(c.penaliteDue)} FCFA',
      if (c.enLitige) 'en litige',
      if (c.referenceTransaction != null) 'réf. ${c.referenceTransaction}',
    ].join(' · ');

    Widget? actions;
    if (c.statut == 'due' && jeDois) {
      actions = Row(children: [
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentDeclareScreen(cotisationId: c.id, cotisation: c)),
          ),
          child: const Text('J’ai payé', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        // Simulation d'Orange Money / MTN MoMo : seulement dans la version de démonstration,
        // le serveur la refuse en production.
        if (comptesDemoActifs) ...[
          const SizedBox(width: 20),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaiementSimuleScreen(cotisation: c))),
            child: const Text('Mobile Money (démo)'),
          ),
        ],
      ]);
    } else if (c.statut == 'declaree' && !jeDois) {
      actions = Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
          onPressed: () => _confirmer(context, ref),
          child: const Text('Confirmer la réception', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    // Comme le profil : icône à gauche (flèche qui sort si je paie, qui entre si je reçois), intitulé et montant
    // signé, état et échéance en dessous.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(jeDois ? Icons.north_east : Icons.south_west, size: 22, color: couleur),
        ),
        const SizedBox(width: Espace.iconeTexte),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  'Tour ${c.tour}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${jeDois ? '−' : '+'}${formatAmount(c.montant)} FCFA',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: jeDois ? AppColors.textDark : AppColors.green),
              ),
            ]),
            const SizedBox(height: 2),
            Text(details, style: TextStyle(fontSize: 14, height: 1.35, color: aFaire ? AppColors.action : AppColors.textMuted)),
            ?actions,
          ]),
        ),
      ]),
    );
  }

  Future<void> _confirmer(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la réception ?'),
        content: Text(
          'Tu confirmes avoir reçu ${formatAmount(c.montant)} FCFA'
          '${c.referenceTransaction != null ? ' (référence ${c.referenceTransaction})' : ''}. '
          'La confirmation est inscrite au registre.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Je confirme')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(cotisationsServiceProvider).confirmerPaiement(cotisationId: c.id);
      ref.invalidate(mesCotisationsRefreshableProvider);
      if (context.mounted) afficherMessage(context, 'Réception confirmée.');
    } catch (e) {
      if (context.mounted) afficherErreur(context, e);
    }
  }
}
