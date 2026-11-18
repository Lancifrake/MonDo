import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Clé de l'appareil : ECDSA P-256 / SHA-256, comme le serveur l'attend.
///
/// - La clé publique part au serveur en JWK (`kty`, `crv`, `x`, `y`).
/// - La signature est au format brut r puis s (64 octets), en base64 STANDARD
///   (pas DER, pas base64url) : voir docs/conception/guide-application-mobile.md, §2.
/// - La clé privée ne sort jamais du téléphone : elle est rangée dans le
///   stockage sécurisé du système par [LocalStorageService].
class CryptoService {
  CryptoService._(this._privee, this._publique);

  static final ECDomainParameters _courbe = ECCurve_secp256r1();

  final ECPrivateKey _privee;
  final ECPublicKey _publique;

  /// Dernier horodatage émis : le serveur refuse deux requêtes identiques,
  /// donc chaque horodatage doit être strictement plus grand que le précédent.
  static int _dernierHorodatage = 0;

  /// Génère une nouvelle paire de clés.
  static Future<CryptoService> generateKeyPair() async {
    final graine = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    final aleatoire = FortunaRandom()..seed(KeyParameter(graine));
    final generateur = ECKeyGenerator()
      ..init(ParametersWithRandom(ECKeyGeneratorParameters(_courbe), aleatoire));
    final paire = generateur.generateKeyPair();
    return CryptoService._(
      paire.privateKey as ECPrivateKey,
      paire.publicKey as ECPublicKey,
    );
  }

  /// Recrée la clé depuis le scalaire privé gardé dans le stockage sécurisé.
  static CryptoService fromPrivateHex(String hex) {
    final d = BigInt.parse(hex, radix: 16);
    final q = _courbe.G * d;
    return CryptoService._(
      ECPrivateKey(d, _courbe),
      ECPublicKey(q, _courbe),
    );
  }

  /// Le scalaire privé en hexadécimal, à ranger UNIQUEMENT dans le stockage sécurisé.
  String privateKeyHex() => _privee.d!.toRadixString(16).padLeft(64, '0');

  /// Clé publique au format JWK attendu par le serveur.
  Future<Map<String, dynamic>> getPublicKeyAsJwk() async => publicJwk;

  Map<String, dynamic> get publicJwk => {
        'kty': 'EC',
        'crv': 'P-256',
        'x': _b64url(_octets32(_publique.Q!.x!.toBigInteger()!)),
        'y': _b64url(_octets32(_publique.Q!.y!.toBigInteger()!)),
      };

  /// Signe un texte et renvoie r||s en base64 standard.
  String signMessage(String message) {
    final signataire = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(true, PrivateKeyParameter<ECPrivateKey>(_privee));
    final sig = signataire.generateSignature(
      Uint8List.fromList(utf8.encode(message)),
    ) as ECSignature;
    return base64.encode([..._octets32(sig.r), ..._octets32(sig.s)]);
  }

  /// Vérifie une signature (utile aux tests).
  bool verify(String message, String signatureBase64) {
    final brut = base64.decode(signatureBase64);
    if (brut.length != 64) return false;
    final r = _versEntier(brut.sublist(0, 32));
    final s = _versEntier(brut.sublist(32));
    final verificateur = ECDSASigner(SHA256Digest())
      ..init(false, PublicKeyParameter<ECPublicKey>(_publique));
    return verificateur.verifySignature(
      Uint8List.fromList(utf8.encode(message)),
      ECSignature(r, s),
    );
  }

  /// Signe une requête : renvoie la signature du message canonique
  /// `{chemin, corps, horodatage, methode}`.
  Future<String> signRequest({
    required String method,
    required String path,
    required String timestamp,
    required dynamic body,
  }) async =>
      signMessage(messageRequete(method, path, timestamp, body));

  /// Preuve d'inscription : le téléphone montre qu'il détient la clé privée.
  String signInscription({required String numero, required String nom}) =>
      signMessage(canonique({
        'objet': 'inscription',
        'numero': numero,
        'nom': nom,
        'clePublique': publicJwk,
      }));

  /// Preuve de récupération depuis un nouveau téléphone.
  String signRecuperation({required String numero}) => signMessage(canonique({
        'objet': 'recuperation',
        'numero': numero,
        'clePublique': publicJwk,
      }));

  /// Horodatage ISO 8601 en millisecondes, strictement croissant.
  static String horodatage() {
    var ms = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (ms <= _dernierHorodatage) ms = _dernierHorodatage + 1;
    _dernierHorodatage = ms;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
  }

  /// Le message que le serveur recalcule pour chaque requête signée.
  static String messageRequete(
    String methode,
    String chemin,
    String horodatage,
    dynamic corps,
  ) =>
      canonique({
        'methode': methode.toUpperCase(),
        'chemin': chemin,
        'horodatage': horodatage,
        'corps': normaliserCorps(corps),
      });

  /// Corps vide et absence de corps se signent pareil : `null`.
  static dynamic normaliserCorps(dynamic corps) =>
      corps is Map && corps.isNotEmpty ? corps : null;

  /// JSON à clés triées à tous les niveaux, sans espace : même règle que
  /// `src/serveur/src/signature/canonique.ts`.
  static String canonique(dynamic valeur) {
    if (valeur is List) return '[${valeur.map(canonique).join(',')}]';
    if (valeur is Map) {
      final cles = valeur.keys.map((k) => k.toString()).toList()..sort();
      return '{${cles.map((k) => '${jsonEncode(k)}:${canonique(valeur[k])}').join(',')}}';
    }
    return jsonEncode(valeur);
  }

  void dispose() {}

  static Uint8List _octets32(BigInt n) {
    final out = Uint8List(32);
    var v = n;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }

  static BigInt _versEntier(List<int> octets) =>
      octets.fold(BigInt.zero, (acc, o) => (acc << 8) | BigInt.from(o));

  static String _b64url(List<int> octets) =>
      base64Url.encode(octets).replaceAll('=', '');
}
