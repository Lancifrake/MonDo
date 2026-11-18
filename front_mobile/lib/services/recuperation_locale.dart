import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';

/// Une récupération de compte demandée DEPUIS CE TÉLÉPHONE et pas encore aboutie.
///
/// La demande est liée à la clé créée ici : si l'app l'oublie (écran quitté, app réinstallée), le
/// serveur finit par remplacer la clé du compte par une clé que personne ne détient plus.
/// On la garde donc dans le stockage sécurisé jusqu'à ce que le compte soit ouvert.
class RecuperationLocale {
  RecuperationLocale({
    required this.numero,
    required this.recuperationId,
    required this.cle,
    required this.finDelaiLe,
    required this.piecesRequises,
  });

  final String numero;
  final String recuperationId;
  final CryptoService cle;
  final String finDelaiLe;
  final bool piecesRequises;

  static const _cle = 'mondo_recuperation_en_cours';
  static const _stockage = FlutterSecureStorage();

  Future<void> enregistrer() => _stockage.write(
        key: _cle,
        value: jsonEncode({
          'numero': numero,
          'id': recuperationId,
          'cle': cle.privateKeyHex(),
          'finDelaiLe': finDelaiLe,
          'piecesRequises': piecesRequises,
        }),
      );

  static Future<RecuperationLocale?> lire() async {
    final brut = await _stockage.read(key: _cle);
    if (brut == null) return null;
    try {
      final d = jsonDecode(brut) as Map<String, dynamic>;
      return RecuperationLocale(
        numero: d['numero'] as String,
        recuperationId: d['id'] as String,
        cle: CryptoService.fromPrivateHex(d['cle'] as String),
        finDelaiLe: d['finDelaiLe'] as String,
        piecesRequises: d['piecesRequises'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> effacer() => _stockage.delete(key: _cle);
}
