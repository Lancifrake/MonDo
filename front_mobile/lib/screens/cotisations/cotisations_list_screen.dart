import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../utils/format.dart';
import '../../widgets/sobre.dart';
import '../cercles/vie_cercle_screens.dart';
import 'payment_declare_screen.dart';

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
      appBar: AppBar(title: const Text('Cotisations')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mesCotisationsRefreshableProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Filtres(
              choix: const {'action': 'À faire', 'due': 'Dues', 'declaree': 'Déclarées', 'confirmee': 'Confirmées'},
              actif: _filtre,
              onChange: (v) => setState(() => _filtre = v),
            ),
            const SizedBox(height: 12),
            ...selon(cotisations, (liste) {
              final vues = liste.where((c) => _filtre == 'action' ? aFaire(c) : c.statut == _filtre).toList();
              if (vues.isEmpty) {
                return [Note(_filtre == 'action' ? 'Rien à faire pour l’instant.' : 'Aucune cotisation ici.')];
              }
              return [for (final c in vues) _Cotisation(c: c, moi: moi, nomCercle: noms[c.cercleId])];
            }, reessayer: () => ref.invalidate(mesCotisationsRefreshableProvider)),
          ],
        ),
      ),
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
    final (statut, ton) = switch (c.statut) {
      'due' when jeDois => ('à payer', Ton.action),
      'due' => ('attendue', Ton.gris),
      'declaree' when !jeDois => ('à confirmer', Ton.action),
      'declaree' => ('déclarée', Ton.gris),
      'confirmee' => ('confirmée', Ton.encre),
      _ => (c.statut, Ton.gris),
    };
    final details = [
      '${jeDois ? 'Je dois' : 'On me doit'} · tour ${c.tour}',
      if (nomCercle != null) nomCercle!,
      'avant le ${formatDate(c.dateLimite)}',
      if (c.penaliteDue > 0) 'pénalité ${formatAmount(c.penaliteDue)} FCFA',
      if (c.enLitige) 'en litige',
      if (c.referenceTransaction != null) 'réf. ${c.referenceTransaction}',
    ].join(' · ');

    Widget? actions;
    if (c.statut == 'due' && jeDois) {
      actions = Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaiementSimuleScreen(cotisation: c))),
            child: const Text('Mobile Money (démo)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentDeclareScreen(cotisationId: c.id, cotisation: c)),
            ),
            child: const Text('J’ai payé'),
          ),
        ),
      ]);
    } else if (c.statut == 'declaree' && !jeDois) {
      actions = ElevatedButton(onPressed: () => _confirmer(context, ref), child: const Text('Confirmer la réception'));
    }

    return Carte(
      titre: '${formatAmount(c.montant)} FCFA',
      detail: details,
      statut: statut,
      ton: ton,
      bas: actions,
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
