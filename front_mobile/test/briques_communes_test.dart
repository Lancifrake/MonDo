import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/widgets/cercle_des_tours.dart';
import 'package:mon_do/widgets/sobre.dart';

Widget _dans(Widget enfant) => MaterialApp(home: Scaffold(body: ListView(children: [enfant])));

void main() {
  // Régression du 19/11 : marge 0 + chevron donnait un retrait négatif et un écran rouge sur la fiche tontine.
  for (final marge in [0.0, 2.0, 20.0]) {
    testWidgets('RangeeIcone cliquable avec marge $marge s’affiche sans erreur', (tester) async {
      await tester.pumpWidget(_dans(RangeeIcone(icone: Icons.receipt_long_outlined, titre: 'Registre', marge: marge, onTap: () {})));
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  }

  testWidgets('CercleDesTours se dessine dans tous les états', (tester) async {
    for (final tour in [0, 1, 3, 4]) {
      await tester.pumpWidget(_dans(CercleDesTours(membres: 3, tourEnCours: tour, maPlace: 2, inscrits: 2)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('CercleDesTours en mode choix : toucher un point choisit la place, pas une place interdite', (tester) async {
    int? choisie;
    await tester.pumpWidget(_dans(Center(
      child: CercleDesTours(membres: 4, maPlace: 4, premierePlace: 2, taille: 200, onPlace: (p) => choisie = p),
    )));
    await tester.pumpAndSettle();
    final centre = tester.getCenter(find.byType(CercleDesTours));
    // Place 2 : à droite (trois heures). Place 1 : en haut, interdite par le score.
    await tester.tapAt(centre + const Offset(85, 0));
    expect(choisie, 2);
    choisie = null;
    await tester.tapAt(centre + const Offset(0, -85));
    expect(choisie, isNull);
    expect(tester.takeException(), isNull);
  });
}
