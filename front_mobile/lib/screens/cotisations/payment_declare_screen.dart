import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cotisations_provider.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';

/// Le payeur déclare avoir payé, hors de l'app, avec la référence de la transaction.
/// Le bénéficiaire confirme ensuite la réception.
class PaymentDeclareScreen extends ConsumerStatefulWidget {
  const PaymentDeclareScreen({super.key, required this.cotisationId, required this.cotisation});

  final String cotisationId;
  final Cotisation cotisation;

  @override
  ConsumerState<PaymentDeclareScreen> createState() => _PaymentDeclareState();
}

class _PaymentDeclareState extends ConsumerState<PaymentDeclareScreen> {
  final _reference = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _declarer() async {
    if (_reference.text.trim().isEmpty) return afficherMessage(context, 'Saisis la référence de la transaction.');
    setState(() => _envoi = true);
    try {
      await ref.read(cotisationsServiceProvider).declarerPaiement(
            cotisationId: widget.cotisationId,
            referenceTransaction: _reference.text,
          );
      ref.invalidate(mesCotisationsRefreshableProvider);
      if (!mounted) return;
      afficherMessage(context, 'Paiement déclaré. Le bénéficiaire doit confirmer la réception.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotisation;
    return Ecran(
      titre: 'Déclarer mon paiement',
      enfants: [
        Bloc(enfants: [
          Ligne('Montant', valeur: '${formatAmount(c.montant)} FCFA'),
          Ligne('Tour', valeur: '${c.tour}'),
          Ligne('À payer avant le', valeur: formatDate(c.dateLimite)),
          if (c.penaliteDue > 0) Ligne('Pénalité de retard', valeur: '${formatAmount(c.penaliteDue)} FCFA', accent: true),
        ]),
        const Titre('Référence'),
        const Note(
          'Paie le bénéficiaire par Orange Money, MTN MoMo ou en espèces, puis recopie la référence '
          'que l’opérateur t’a envoyée par SMS. En espèces, écris par exemple « espèces, remis à Paul ».',
        ),
        Champ(controleur: _reference, libelle: 'Référence de la transaction', indice: 'MP241118.1532.A12345'),
      ],
      bas: AppButton(label: 'Déclarer le paiement', isLoading: _envoi, onPressed: _declarer),
    );
  }
}
