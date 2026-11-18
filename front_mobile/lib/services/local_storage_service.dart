import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'crypto_service.dart';

/// Service de stockage local pour les données persistentes
/// 
/// Gère :
/// - Stockage sécurisé des clés privées (flutter_secure_storage)
/// - Stockage des données publiques (shared_preferences)
/// - Restauration de la session au démarrage
class LocalStorageService {
  static const String _keyMembreId = 'mondo_membre_id';
  static const String _keyPhoneNumber = 'mondo_phone_number';
  static const String _keyPrivateKeyData = 'mondo_private_key';
  static const String _keyPublicKeyData = 'mondo_public_key';
  static const String _keyIsAuthenticated = 'mondo_is_authenticated';

  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  LocalStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Sauvegarde les données de session après authentification
  Future<void> saveSession({
    required String membreId,
    required String phoneNumber,
    required CryptoService cryptoService,
  }) async {
    try {
      _logger.i('Sauvegarde de la session');

      final prefs = await SharedPreferences.getInstance();

      // Sauvegarder les données publiques
      await prefs.setString(_keyMembreId, membreId);
      await prefs.setString(_keyPhoneNumber, phoneNumber);
      await prefs.setBool(_keyIsAuthenticated, true);

      // Clé privée : UNIQUEMENT dans le stockage sécurisé (Keychain / Keystore)
      await _secureStorage.write(
        key: _keyPrivateKeyData,
        value: cryptoService.privateKeyHex(),
      );
      final publicKeyJwk = await cryptoService.getPublicKeyAsJwk();
      await _secureStorage.write(
        key: _keyPublicKeyData,
        value: jsonEncode(publicKeyJwk),
      );

      _logger.i('Session sauvegardée');
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde de la session: $e');
      rethrow;
    }
  }

  /// Récupère la session sauvegardée
  Future<SavedSession?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final membreId = prefs.getString(_keyMembreId);
      final phoneNumber = prefs.getString(_keyPhoneNumber);
      final isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;

      if (!isAuthenticated || membreId == null || phoneNumber == null) {
        _logger.i('Aucune session sauvegardée');
        return null;
      }

      final publicKeyDataStr =
          await _secureStorage.read(key: _keyPublicKeyData);

      if (publicKeyDataStr == null) {
        _logger.w('Clé publique non trouvée');
        return null;
      }

      final publicKeyJwk = jsonDecode(publicKeyDataStr) as Map<String, dynamic>;
      final privateKeyHex = await _secureStorage.read(key: _keyPrivateKeyData);
      if (privateKeyHex == null) {
        _logger.w('Clé privée non trouvée');
        return null;
      }

      _logger.i('Session restaurée pour: $membreId');

      return SavedSession(
        membreId: membreId,
        phoneNumber: phoneNumber,
        publicKeyJwk: publicKeyJwk,
        cryptoService: CryptoService.fromPrivateHex(privateKeyHex),
      );
    } catch (e) {
      _logger.e('Erreur lors de la récupération de la session: $e');
      return null;
    }
  }

  /// Efface la session (déconnexion)
  Future<void> clearSession() async {
    try {
      _logger.i('Effacement de la session');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMembreId);
      await prefs.remove(_keyPhoneNumber);
      await prefs.remove(_keyIsAuthenticated);
      await _secureStorage.delete(key: _keyPublicKeyData);
      await _secureStorage.delete(key: _keyPrivateKeyData);
      await _secureStorage.delete(key: 'mondo_pin_empreinte');

      _logger.i('Session effacée');
    } catch (e) {
      _logger.e('Erreur lors de l\'effacement de la session: $e');
      rethrow;
    }
  }

  /// Retourne l'ID du membre actuellement connecté
  Future<String?> getMembreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMembreId);
  }

  /// Retourne le numéro de téléphone actuellement connecté
  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  /// Vérifie s'il existe une session sauvegardée
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAuthenticated) ?? false;
  }

  /// Sauvegarde une donnée temporaire (pour les étapes d'authentification)
  Future<void> saveTempData({
    required String key,
    required String value,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_$key', value);
    } catch (e) {
      _logger.e('Erreur lors de la sauvegarde de donnée temporaire: $e');
      rethrow;
    }
  }

  /// Récupère une donnée temporaire
  Future<String?> getTempData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('temp_$key');
    } catch (e) {
      _logger.e('Erreur lors de la récupération de donnée temporaire: $e');
      return null;
    }
  }

  /// Efface une donnée temporaire
  Future<void> clearTempData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_$key');
    } catch (e) {
      _logger.e('Erreur lors de l\'effacement de donnée temporaire: $e');
    }
  }

  /// Efface toutes les données temporaires
  Future<void> clearAllTempData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('temp_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'effacement des données temporaires: $e');
    }
  }
}

/// Données de session sauvegardées
class SavedSession {
  final String membreId;
  final String phoneNumber;
  final Map<String, dynamic> publicKeyJwk;
  final CryptoService cryptoService;

  SavedSession({
    required this.membreId,
    required this.phoneNumber,
    required this.publicKeyJwk,
    required this.cryptoService,
  });
}
