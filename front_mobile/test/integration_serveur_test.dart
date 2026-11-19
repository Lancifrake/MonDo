// Essai de bout en bout contre un VRAI serveur, avec les services de l'app.
// Ignoré tant que MONDO_E2E_LOG n'est pas défini.
//
// Serveur local (le code SMS simulé s'écrit dans son journal) :
//   cd src/serveur && NODE_ENV=development PORT=3100 node dist/main.js > /tmp/serveur.log
//   MONDO_E2E_LOG=/tmp/serveur.log flutter test test/integration_serveur_test.dart \
//     --dart-define=API_URL=http://127.0.0.1:3100
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/services/api_client.dart';
import 'package:mon_do/services/auth_service.dart';
import 'package:mon_do/services/cercles_service.dart';
import 'package:mon_do/services/cotisations_service.dart';
import 'package:mon_do/services/litiges_service.dart';
import 'package:mon_do/services/notifications_service.dart';
import 'package:mon_do/services/score_service.dart';

void main() {
  final journal = Platform.environment['MONDO_E2E_LOG'];

  Future<String> codeSms(String numero) async {
    for (var i = 0; i < 20; i++) {
      final ligne = File(journal!).readAsLinesSync().reversed.firstWhere(
            (l) => l.contains(numero),
            orElse: () => '',
          );
      final m = RegExp(r'(\d{6})').firstMatch(ligne.substring(ligne.indexOf(numero) + numero.length));
      if (ligne.isNotEmpty && m != null) return m.group(1)!;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('Code SMS introuvable pour $numero');
  }

  Future<ApiClient> inscrire(String numero, String nom) async {
    final api = ApiClient();
    final auth = AuthService(api);
    await auth.requestOtp(numero);
    final compte = await auth.signup(phoneNumber: numero, nom: nom, otp: await codeSms(numero));
    expect((await auth.getMoi()).id, compte.id);
    await api.post<dynamic>('/comptes/${compte.id}/niveau2', data: const {}, fromJson: (j) => j);
    return api;
  }

  test('parcours complet avec les services de l’app', () async {
    final suffixe = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final amina = await inscrire('+23762$suffixe' '001', 'Amina Essai');
    final bello = await inscrire('+23762$suffixe' '002', 'Bello Essai');

    // Amina crée une tontine ouverte : règlement signé
    final cercles = CerclesService(amina);
    final cree = await cercles.createCercle(
      montant: 10000,
      frequence: 'hebdomadaire',
      nombreMembres: 4,
      ouvert: true,
      datePremierTour: DateTime.now().add(const Duration(days: 7)),
      penaliteRetard: 500,
      delaiGraceJours: 2,
    );
    expect(cree.statut, 'en_attente');

    // Bello la trouve au catalogue et la rejoint : engagement signé
    final catalogue = await CerclesService(bello).getCatalogue();
    final vue = catalogue.firstWhere((c) => c.id == cree.id);
    final rejoint = await CerclesService(bello).adhererAuCercle(cercle: vue, placeSouhaitee: 4);
    expect(rejoint.membres, contains(bello.membreId));

    // Démo : deux membres fictifs complètent la tontine
    await cercles.demoMembresFictifs(cree.id);
    final mes = await cercles.getMesCercles();
    expect(mes.single.statut, 'complet');
    expect(mes.single.nombreInscrits, 4);
    final detail = await cercles.getCercle(cree.id);
    expect(detail.ordre, hasLength(4));

    // Cotisations : Amina déclare, les fictifs jouent le tour
    final cotis = CotisationsService(amina);
    final aPayer = (await cotis.getMesCotisations(statut: 'due')).where((c) => c.payeurId == amina.membreId);
    final premiere = aPayer.reduce((a, b) => a.tour <= b.tour ? a : b);
    final declaree = await cotis.declarerPaiement(cotisationId: premiere.id, referenceTransaction: 'OM-E2E-1');
    expect(declaree.statut, 'declaree');
    await cercles.demoSuite(cree.id);
    final etat = await cotis.getEtatCercle(cree.id);
    expect(etat.tours.first.membres, isNotEmpty);

    // Bello confirme ce qu'on lui a déclaré, s'il est bénéficiaire d'un paiement déclaré
    final pourBello = (await CotisationsService(bello).getMesCotisations(statut: 'declaree'))
        .where((c) => c.beneficiaireId == bello.membreId);
    for (final c in pourBello) {
      expect((await CotisationsService(bello).confirmerPaiement(cotisationId: c.id)).statut, 'confirmee');
    }

    final score = await ScoreService(amina).getMonScore();
    expect(score.membreId, amina.membreId);
    final boite = await NotificationsService(amina).getBoite();
    expect(boite.nonLues, greaterThanOrEqualTo(0));
    await LitigesService(amina).getMesLitiges();
    await cotis.getSommesDues();

    // ignore: avoid_print
    print('OK : score ${score.score}, ${boite.notifications.length} notification(s), '
        '${etat.tours.length} tours, ${pourBello.length} confirmation(s) par Bello');
  }, skip: journal == null, timeout: const Timeout(Duration(minutes: 2)));

  test('tontine privée de nouveaux : l’organisateur fixe l’ordre, chacun le signe', () async {
    final suffixe = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final orga = await inscrire('+23763$suffixe' '001', 'Orga Essai');
    final soeur = await inscrire('+23763$suffixe' '002', 'Soeur Essai');
    final cousin = await inscrire('+23763$suffixe' '003', 'Cousin Essai');
    final inconnu = await inscrire('+23763$suffixe' '004', 'Inconnu Essai');

    // L'organisatrice met sa sœur en premier, elle-même en 2, le cousin en 3 (null = sa propre place)
    final cree = await CerclesService(orga).createCercle(
      montant: 10000,
      frequence: 'mensuelle',
      nombreMembres: 3,
      ouvert: false,
      datePremierTour: DateTime.now().add(const Duration(days: 7)),
      penaliteRetard: 500,
      delaiGraceJours: 3,
      ordreFixe: [soeur.membreId, null, cousin.membreId],
    );
    expect(cree.reglement.ordreFixe, [soeur.membreId, orga.membreId, cousin.membreId]);

    // Chacun voit sa place avant de signer ; un inconnu avec le lien ne la voit pas et ne peut pas entrer
    final vueSoeur = await CerclesService(soeur).getCercle(cree.id);
    expect(vueSoeur.ordreFixeParOrganisateur, isTrue);
    expect(vueSoeur.placeFixee, 1);
    final vueInconnu = await CerclesService(inconnu).getCercle(cree.id);
    expect(vueInconnu.placeFixee, isNull);
    await expectLater(
      CerclesService(inconnu).adhererAuCercle(cercle: vueInconnu, placeSouhaitee: 3),
      throwsA(anything),
    );

    // Score à 0 pour tous : la sœur prend quand même la place 1, puisque l'ordre est signé par tous
    await CerclesService(soeur).adhererAuCercle(cercle: vueSoeur, placeSouhaitee: vueSoeur.placeFixee!);
    final vueCousin = await CerclesService(cousin).getCercle(cree.id);
    await CerclesService(cousin).adhererAuCercle(cercle: vueCousin, placeSouhaitee: vueCousin.placeFixee!);

    final detail = await CerclesService(orga).getCercle(cree.id);
    expect(detail.statut, 'complet');
    expect([for (final p in [...detail.ordre!]..sort((a, b) => a.position.compareTo(b.position))) p.membreId],
        [soeur.membreId, orga.membreId, cousin.membreId]);
  }, skip: journal == null, timeout: const Timeout(Duration(minutes: 2)));
}
