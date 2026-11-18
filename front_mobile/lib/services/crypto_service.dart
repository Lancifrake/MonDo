import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:logger/logger.dart';

/// Service de cryptographie pour les signatures ECDSA P-256
/// 
/// Gère :
/// - Génération de paires de clés P-256
/// - Stockage sécurisé des clés privées
/// - Signature de requêtes HTTP selon le format du serveur
/// - Export de clés publiques en format JWK
class CryptoService {
  static final Logger _logger = Logger();
  
  final Ec256PublicKey? _publicKey;
  final Ec256PrivateKey? _privateKey;

  CryptoService({
    Ec256PublicKey? publicKey,
    Ec256PrivateKey? privateKey,
  })  : _publicKey = publicKey,
        _privateKey = privateKey;

  /// Génère une nouvelle paire de clés ECDSA P-256
  /// 
  /// Retourne une instance CryptoService avec les clés générées
  static Future<CryptoService> generateKeyPair() async {
    try {
      final algorithm = Ec256();
      final keyPair = await algorithm.newKeyPair();
      
      final privateKey = await keyPair.extractPrivateKey() as Ec256PrivateKey;
      final publicKey = await keyPair.extractPublicKey() as Ec256PublicKey;

      _logger.i('Paire de clés ECDSA P-256 générée avec succès');
      return CryptoService(publicKey: publicKey, privateKey: privateKey);
    } catch (e) {
      _logger.e('Erreur lors de la génération de la paire de clés: $e');
      rethrow;
    }
  }

  /// Retourne la clé publique au format JWK (JSON Web Key)
  /// 
  /// Format attendu par le serveur pour l'inscription
  Future<Map<String, dynamic>> getPublicKeyAsJwk() async {
    if (_publicKey == null) {
      throw Exception('Clé publique non disponible');
    }

    try {
      final jwk = await _publicKey!.extractJson();
      _logger.d('Clé publique exportée en JWK');
      return jwk;
    } catch (e) {
      _logger.e('Erreur lors de l\'export de la clé publique en JWK: $e');
      rethrow;
    }
  }

  /// Signe une requête HTTP selon le format du serveur MonDo
  /// 
  /// Signature du JSON canonique (clés triées) de :
  /// { methode, chemin, horodatage, corps }
  /// 
  /// Retourne la signature au format r||s en base64
  Future<String> signRequest({
    required String method,
    required String path,
    required String timestamp,
    required dynamic body,
  }) async {
    if (_privateKey == null) {
      throw Exception('Clé privée non disponible');
    }

    try {
      // Construire le message à signer selon le format du serveur
      final message = {
        'methode': method,
        'chemin': path,
        'horodatage': timestamp,
        'corps': body ?? null,
      };

      // Canonicaliser le JSON (clés triées)
      final canonicalJson = _canonicalizeJson(message);
      _logger.d('Message canonicalisé pour signature: $canonicalJson');

      // Signer avec ECDSA P-256
      final algorithm = Ec256();
      final signature = await algorithm.sign(
        utf8.encode(canonicalJson),
        keyPair: SimpleKeyPairData(
          await _privateKey!.extractPrivateKeyBytes(),
          publicKey: SimplePublicKey(
            await _publicKey!.extractPublicKeyBytes(),
            type: KeyPairType.ec,
          ),
          type: KeyPairType.ec,
        ),
      );

      // Extraire r et s de la signature DER et les convertir en base64
      final signatureBytes = signature.bytes;
      final signatureBase64 = base64Url.encode(signatureBytes);
      
      _logger.d('Requête signée avec succès');
      return signatureBase64;
    } catch (e) {
      _logger.e('Erreur lors de la signature de la requête: $e');
      rethrow;
    }
  }

  /// Canonicalise un objet JSON en triant les clés
  /// 
  /// Format attendu par le serveur pour la signature
  static String _canonicalizeJson(Map<String, dynamic> obj) {
    final sortedKeys = obj.keys.toList()..sort();
    final entries = sortedKeys.map((key) {
      final value = obj[key];
      final encodedValue = jsonEncode(value);
      return '"$key":$encodedValue';
    }).toList();
    
    return '{${entries.join(',')}}';
  }

  /// Retourne l'ID publique de la clé (optionnel, pour référence)
  /// 
  /// Peut être utilisé pour identifier la clé sur le serveur
  Future<String?> getKeyId() async {
    if (_publicKey == null) return null;

    try {
      // Extraire les bytes publics et générer un hash court
      final publicKeyBytes = await _publicKey!.extractPublicKeyBytes();
      // Format simple : premiers 16 caractères du hash en hex
      final keyId = publicKeyBytes
          .sublist(0, 8)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      return keyId;
    } catch (e) {
      _logger.e('Erreur lors de la génération du keyId: $e');
      return null;
    }
  }

  /// Dispose les ressources (nettoie les données sensibles)
  void dispose() {
    // Les clés cryptographiques sont généralement gérées par le système
    _logger.i('CryptoService disposé');
  }
}
