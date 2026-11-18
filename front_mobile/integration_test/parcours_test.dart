// Parcours réel dans l'app (simulateur), contre un serveur MonDo local.
//
//   cd src/serveur && NODE_ENV=development PORT=3100 node dist/main.js > /tmp/serveur.log
//   flutter test integration_test/parcours_test.dart -d <simulateur> \
//     --dart-define=API_URL=http://127.0.0.1:3100 --dart-define=MONDO_E2E_LOG=/tmp/serveur.log
//
// Le code SMS simulé est lu dans le journal du serveur (le simulateur voit les fichiers du Mac).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mon_do/main.dart' as app;

const journal = String.fromEnvironment('MONDO_E2E_LOG');

Future<String> codeSms(String numero) async {
  for (var i = 0; i < 30; i++) {
    final lignes = File(journal).readAsLinesSync().reversed;
    final ligne = lignes.firstWhere((l) => l.contains(numero), orElse: () => '');
    final m = RegExp(r'(\d{6})').firstMatch(ligne.isEmpty ? '' : ligne.substring(ligne.indexOf(numero) + numero.length));
    if (m != null) return m.group(1)!;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw StateError('Code introuvable pour $numero');
}

Future<void> attendre(WidgetTester t, Finder f, {int secondes = 15}) async {
  for (var i = 0; i < secondes * 4; i++) {
    await t.pump(const Duration(milliseconds: 250));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Introuvable à l’écran : $f');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inscription, création signée d’une tontine, accueil réel', (t) async {
    final suffixe = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    final telephone = '600001$suffixe';

    app.main();
    await attendre(t, find.text('Créer mon compte'));
    await t.tap(find.text('Créer mon compte'));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField).at(0), 'Amina Njoya');
    await t.enterText(find.byType(TextField).at(1), telephone);
    await t.pump();
    await t.tap(find.text('Recevoir le code par SMS'));
    await attendre(t, find.text('Vérifier'));

    await t.enterText(find.byType(TextField).last, await codeSms('+237$telephone'));
    await t.pump();
    await t.tap(find.text('Vérifier'));
    await attendre(t, find.text('Choisis ton code PIN'));

    // Le PIN se saisit deux fois à la création
    for (var fois = 0; fois < 2; fois++) {
      for (final k in ['1', '2', '3', '4']) {
        await t.tap(find.text(k).last);
        await t.pump(const Duration(milliseconds: 100));
      }
      if (fois == 0) await attendre(t, find.text('Confirme ton code PIN'));
    }
    await attendre(t, find.text('Bonjour, Amina.'));
    await attendre(t, find.text('Mes tontines'));

    // Création d'une tontine : modèle, montant et membres, règlement signé
    await t.tap(find.text('Créer'));
    await attendre(t, find.text('Ton modèle'));
    await t.tap(find.text('Continuer'));
    await attendre(t, find.text('Ta tontine'));
    await t.tap(find.text("Ouverte à d'autres personnes"));
    await t.pump();
    await t.tap(find.text('Continuer'));
    await attendre(t, find.text('Ton règlement'));
    await attendre(t, find.textContaining('Place 1'));
    await t.tap(find.text('Signer et créer'));
    await attendre(t, find.textContaining('Tontine de 10'));

    // L'accueil montre la tontine créée, lue sur le serveur
    expect(find.text('Mes tontines'), findsOneWidget);

    // Fiche de la tontine : compléter avec des membres fictifs, puis le registre
    await t.tap(find.textContaining('Tontine de 10').first);
    await attendre(t, find.text('Démo : remplir avec des fictifs'));
    await t.ensureVisible(find.text('Démo : remplir avec des fictifs'));
    await t.tap(find.text('Démo : remplir avec des fictifs'));
    await attendre(t, find.text('Registre et preuve d’intégrité'));
    await t.ensureVisible(find.text('Registre et preuve d’intégrité'));
    await t.tap(find.text('Registre et preuve d’intégrité'));
    await attendre(t, find.textContaining('Intégrité vérifiée'));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byTooltip('Back').last);
      await t.pumpAndSettle();
    }

    // Chaque onglet se charge depuis le serveur, sans erreur
    for (final onglet in ['Cotisations', 'Litiges', 'Alertes', 'Profil']) {
      await t.tap(find.text(onglet).last);
      await t.pump(const Duration(seconds: 2));
      expect(find.textContaining('Exception'), findsNothing, reason: onglet);
      expect(find.textContaining('Erreur'), findsNothing, reason: onglet);
    }
    await attendre(t, find.text('Code secret de récupération'));

    // Laisser l'écran affiché pour la capture
    await t.pump(const Duration(seconds: 20));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
