import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/screens/compte/profil_screen.dart';
import 'package:mon_do/screens/otp_screen.dart';
import 'package:mon_do/theme/app_colors.dart';
import 'package:mon_do/theme/app_theme.dart';

// Écrans qu'on n'atteint pas avec les comptes de démonstration : le code SMS (inscription d'un
// nouveau numéro) et l'alerte de récupération (il faut qu'un autre téléphone la déclenche).
// On vérifie qu'ils s'ouvrent sans erreur, dans les deux modes.
Widget _app(Widget ecran, {required bool sombre}) {
  AppColors.sombre = sombre;
  return ProviderScope(
    child: MaterialApp(theme: sombre ? AppTheme.dark : AppTheme.light, home: ecran),
  );
}

void main() {
  tearDown(() => AppColors.sombre = false);

  for (final sombre in [false, true]) {
    final mode = sombre ? 'sombre' : 'clair';

    testWidgets('Code SMS s’ouvre sans erreur ($mode)', (tester) async {
      await tester.pumpWidget(_app(const OtpScreen(phone: '690000099', nom: 'Test'), sombre: sombre));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(OtpScreen), findsOneWidget);
      // Le minuteur du renvoi tourne : on démonte l'écran pour l'arrêter.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Alerte de récupération s’ouvre sans erreur ($mode)', (tester) async {
      await tester.pumpWidget(_app(
        const RecuperationAlerteScreen(demande: {
          'demandeeLe': '2026-11-19T10:00:00.000Z',
          'finDelaiLe': '2026-11-21T10:00:00.000Z',
        }),
        sombre: sombre,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('m’opposer'), findsOneWidget);
    });
  }
}
