import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/pin_pad.dart';
import '../group/group_screen.dart';
import 'request_sent_screen.dart';

class CommitPinScreen extends StatelessWidget {
  const CommitPinScreen({super.key, required this.tontine});

  final CatalogTontine tontine;

  void _confirmed(BuildContext context) {
    if (tontine.joinMode == JoinMode.onRequest) {
      // Tontine sur demande : l'organisateur doit accepter
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RequestSentScreen(tontine: tontine)),
      );
    } else {
      // Entrée libre : la tontine arrive dans « Mes tontines » de l'accueil,
      // puis on ouvre le groupe. On garde seulement l'accueil derrière,
      // le retour ramène donc à l'accueil.
      appState.joinTontine(tontine);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => GroupScreen(tontine: tontine)),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, "Je m'engage"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirme avec ton code PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              "En signant, tu t'engages à respecter le règlement de "
              '« ${tontine.name} ».',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            PinPad(onCompleted: (_) => _confirmed(context)),
          ],
        ),
      ),
    );
  }
}