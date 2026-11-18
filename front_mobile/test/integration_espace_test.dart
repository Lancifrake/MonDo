// Les pages ajoutées (compte, sécurité, vie d'une tontine) contre un VRAI serveur.
// Même lancement que integration_serveur_test.dart (MONDO_E2E_LOG + API_URL).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/services/api_client.dart';
import 'package:mon_do/services/auth_service.dart';
import 'package:mon_do/services/cercles_service.dart';
import 'package:mon_do/services/cotisations_service.dart';
import 'package:mon_do/services/crypto_service.dart';
import 'package:mon_do/services/espace_service.dart';

void main() {
  final journal = Platform.environment['MONDO_E2E_LOG'];

  Future<String> codeSms(String numero) async {
    for (var i = 0; i < 25; i++) {
      final ligne = File(journal!).readAsLinesSync().reversed.firstWhere((l) => l.contains(numero), orElse: () => '');
      final m = RegExp(r'(\d{6})').firstMatch(ligne.isEmpty ? '' : ligne.substring(ligne.indexOf(numero) + numero.length));
      if (m != null) return m.group(1)!;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('Code SMS introuvable pour $numero');
  }

  test('compte, sécurité et vie d’une tontine', () async {
    final s = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final numeroA = '+23763${s}001';
    final api = ApiClient();
    final auth = AuthService(api);
    await auth.requestOtp(numeroA);
    final compte = await auth.signup(phoneNumber: numeroA, nom: 'Amina Espace', otp: await codeSms(numeroA));
    final e = EspaceService(api);

    // Sécurité : code secret, contact de confiance (avec son accord), identité
    await e.definirCodeSecret('4821');
    expect(await e.contactDeConfiance(), isNull);
    final contactNumero = '+23763${s}009';
    final designe = await e.designerContact(nom: 'Tante Espace', numero: contactNumero);
    expect(designe['statut'], 'en_attente');
    expect((await e.accordDuContact(await codeSms(contactNumero)))['statut'], 'accepte');
    final consentement = await e.consentementIdentite();
    expect(consentement['version'], isNotEmpty);
    expect(await e.monIdentite(), isNull);
    const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    final dossier = await e.deposerIdentite(
      typePiece: 'cni',
      versionConsentement: consentement['version'] as String,
      recto: png,
      verso: png,
      selfie: png,
    );
    expect(dossier['statut'], 'en_attente');
    expect((await e.monIdentite())!['statut'], 'en_attente');
    final parrainages = await e.parrainages();
    expect(parrainages.keys, containsAll(['commeParrain', 'commeFilleul']));

    // Tontine complète (niveau 2 de démonstration pour une tontine ouverte)
    await api.post<dynamic>('/comptes/${compte.id}/niveau2', data: const {}, fromJson: (j) => j);
    final cercles = CerclesService(api);
    final c = await cercles.createCercle(
      montant: 5000,
      frequence: 'jours',
      periodeJours: 10,
      nombreMembres: 4,
      ouvert: true,
      datePremierTour: DateTime.now().add(const Duration(days: 7)),
      penaliteRetard: 500,
      delaiGraceJours: 2,
      scoreMinimum: 0,
      rappelsAvantEcheanceJours: const [3, 1],
    );
    await cercles.demoMembresFictifs(c.id);
    final complet = await cercles.getCercle(c.id);
    expect(complet.statut, 'complet');

    expect((await e.registre(c.id))['integre'], isTrue);
    expect(await e.echanges(c.id), isEmpty);
    expect((await e.modeAssistant(c.id, 'manuel'))['mode'], 'manuel');

    // Mobile Money simulé : un paiement réussi déclare la cotisation
    final cotis = await CotisationsService(api).getCotisationsCercle(c.id);
    final maDue = cotis.firstWhere((x) => x.payeurId == compte.id && x.tour == 1);
    final simule = await e.paiementSimule(maDue.id, operateur: 'mtn_momo', issue: 'reussi');
    expect(simule['statut'], 'reussi');
    expect(await e.paiementsSimules(maDue.id), hasLength(1));
    final apres = (await CotisationsService(api).getCotisationsCercle(c.id)).firstWhere((x) => x.id == maDue.id);
    expect(apres.statut, 'declaree');

    // Le temps avance : défaut d'un fictif, l'assistant propose (mode manuel), dossier de preuve
    await cercles.demoSuite(c.id);
    await api.post<dynamic>('/demonstration/cercles/${c.id}/avance', data: const {'jours': 25}, fromJson: (j) => j);
    final journalAssistant = await e.journalAssistant(c.id);
    expect(journalAssistant, isNotEmpty);
    final aDecider = journalAssistant.where((x) => x['issue'] == 'en_attente').toList();
    if (aDecider.isNotEmpty) await e.deciderProposition(aDecider.first['id'] as String, accepte: true);
    var dossiers = 0;
    for (final m in complet.membres.where((m) => m != compte.id)) {
      if (await e.dossierDePreuve(c.id, m) != null) dossiers++;
    }
    expect(dossiers, greaterThan(0));
    await e.sommesDues();

    // Départ refusé hors règle (le serveur explique pourquoi) ou accepté
    try {
      await e.quitter(c.id);
    } on ApiException catch (err) {
      expect(err.statusCode, anyOf(400, 403, 409));
    }

    // Récupération depuis un « nouveau téléphone », puis opposition depuis l'ancien
    final nouveau = await CryptoService.generateKeyPair();
    final public = ApiClient();
    await public.post<dynamic>('/comptes/otp', data: {'numero': numeroA}, fromJson: (j) => j);
    final demande = await public.post<Map<String, dynamic>>(
      '/comptes/recuperation',
      data: {
        'numero': numeroA,
        'clePublique': nouveau.publicJwk,
        'preuve': nouveau.signRecuperation(numero: numeroA),
        'codeOtp': await codeSms(numeroA),
        'codeSecret': '4821',
      },
      fromJson: (j) => j as Map<String, dynamic>,
    );
    expect(demande['statut'], 'en_attente');
    expect((await e.recuperationEnCours())!['id'], demande['id']);
    expect((await e.sOpposerALaRecuperation())['statut'], 'opposee');

    // ignore: avoid_print
    print('OK espace : ${journalAssistant.length} action(s) d’assistant, $dossiers dossier(s) de preuve');
  }, skip: journal == null, timeout: const Timeout(Duration(minutes: 2)));
}
