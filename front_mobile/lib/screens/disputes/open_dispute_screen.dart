import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../providers/litiges_provider.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';

/// Ouvrir un litige sur un paiement DÉCLARÉ et pas encore confirmé (POST /litiges).
/// Le payeur doit attendre 48 h de confirmation ; le bénéficiaire peut contester tout de suite.
class OpenDisputeScreen extends ConsumerStatefulWidget {
  const OpenDisputeScreen({super.key});

  @override
  ConsumerState<OpenDisputeScreen> createState() => _OpenDisputeState();
}

class _OpenDisputeState extends ConsumerState<OpenDisputeScreen> {
  String? _cotisation;
  final _motif = TextEditingController();
  bool _envoi = false;

  Future<void> _ouvrir() async {
    if (_cotisation == null) return afficherMessage(context, 'Choisis le paiement concerné.');
    if (_motif.text.trim().isEmpty) return afficherMessage(context, 'Explique ce qui ne va pas.');
    setState(() => _envoi = true);
    try {
      await ref.read(litigesServiceProvider).ouvrirLitige(cotisationId: _cotisation!, motif: _motif.text);
      ref.invalidate(mesLitigesRefreshableProvider);
      ref.invalidate(mesCotisationsRefreshableProvider);
      if (!mounted) return;
      afficherMessage(context, 'Litige ouvert. Un administrateur MonDo va l’examiner.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moi = ref.read(apiClientProvider).membreId;
    final cotisations = ref.watch(mesCotisationsRefreshableProvider);
    return Ecran(
      titre: 'Ouvrir un litige',
      enfants: [
        const Note(
          'Pour un paiement déclaré que le bénéficiaire ne confirme pas, ou un paiement qu’on te déclare '
          'et que tu n’as pas reçu. Le payeur doit attendre 48 h après sa déclaration.',
        ),
        const Titre('Paiement concerné'),
        ...selon(cotisations, (liste) {
          final possibles = liste.where((c) => c.statut == 'declaree' && !c.enLitige).toList();
          if (possibles.isEmpty) return const [Note('Aucun paiement déclaré en attente de confirmation.')];
          return [
            Bloc(enfants: [
              for (final c in possibles)
                RadioListTile<String>(
                  value: c.id,
                  groupValue: _cotisation,
                  onChanged: (v) => setState(() => _cotisation = v),
                  title: Text('${formatAmount(c.montant)} FCFA · tour ${c.tour}'),
                  subtitle: Text(
                    '${c.payeurId == moi ? 'Je l’ai déclaré' : 'Déclaré pour moi'}'
                    '${c.referenceTransaction != null ? ' · réf. ${c.referenceTransaction}' : ''}',
                  ),
                ),
            ]),
          ];
        }),
        const Titre('Ce qui ne va pas'),
        TextField(
          controller: _motif,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(hintText: 'Ex. j’ai payé le 12 par Orange Money, sans confirmation depuis.'),
        ),
      ],
      bas: AppButton(label: 'Ouvrir le litige', isLoading: _envoi, onPressed: _ouvrir),
    );
  }
}
