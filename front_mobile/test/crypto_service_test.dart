import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/services/crypto_service.dart';

void main() {
  group('message canonique (vecteurs du guide mobile, §3)', () {
    test('GET sans corps', () {
      expect(
        CryptoService.messageRequete('get', '/cercles', '2026-11-16T12:00:00.000Z', null),
        '{"chemin":"/cercles","corps":null,"horodatage":"2026-11-16T12:00:00.000Z","methode":"GET"}',
      );
    });

    test('POST avec corps', () {
      expect(
        CryptoService.messageRequete(
          'POST',
          '/cotisations/abc/paiement',
          '2026-11-16T12:00:01.000Z',
          {'referenceTransaction': 'OM-123'},
        ),
        '{"chemin":"/cotisations/abc/paiement","corps":{"referenceTransaction":"OM-123"},"horodatage":"2026-11-16T12:00:01.000Z","methode":"POST"}',
      );
    });

    test('corps vide = null, clés imbriquées triées', () {
      expect(CryptoService.normaliserCorps(<String, dynamic>{}), isNull);
      expect(CryptoService.canonique({'b': {'z': 1, 'a': [2, {'y': 0, 'x': 'é'}]}, 'a': true}),
          '{"a":true,"b":{"a":[2,{"x":"é","y":0}],"z":1}}');
    });
  });

  test('signature r||s de 64 octets, vérifiable, clé restaurable', () async {
    final cle = await CryptoService.generateKeyPair();
    final sig = cle.signMessage('bonjour');
    expect(base64.decode(sig).length, 64);
    expect(cle.verify('bonjour', sig), isTrue);
    expect(cle.verify('bonsoir', sig), isFalse);

    final restauree = CryptoService.fromPrivateHex(cle.privateKeyHex());
    expect(restauree.publicJwk, cle.publicJwk);
    expect(cle.verify('bonjour', restauree.signMessage('bonjour')), isTrue);

    // Vecteur pour la vérification croisée par WebCrypto (Node), voir le test du serveur.
    final sortie = Platform.environment['MONDO_VECTEUR'];
    if (sortie != null) {
      final message = cle.signInscription(numero: '+237600000999', nom: 'Test');
      File(sortie).writeAsStringSync(jsonEncode({'jwk': cle.publicJwk, 'signature': message}));
    }
  });

  test('horodatages strictement croissants', () {
    final a = CryptoService.horodatage();
    final b = CryptoService.horodatage();
    expect(DateTime.parse(b).isAfter(DateTime.parse(a)), isTrue);
  });
}
