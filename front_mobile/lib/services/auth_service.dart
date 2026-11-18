import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';
import 'crypto_service.dart';

/// Service d'authentification pour MonDo
/// 
/// Gère :
/// - Demande d'OTP par SMS
/// - Inscription avec vérification OTP
/// - Connexion existante
/// - Récupération de compte
/// - Profil utilisateur
class AuthService {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  // États temporaires pendant l'authentification
  String? _currentPhoneNumber;
  String? _currentOtp;
  CryptoService? _cryptoService;

  AuthService(this._apiClient);

  /// Demande un code OTP pour un numéro de téléphone
  /// 
  /// Envoie un SMS avec le code à :237XXXXXXXXX
  Future<void> requestOtp(String phoneNumber) async {
    try {
      _logger.i('Demande OTP pour: $phoneNumber');

      final request = {
        'numero': phoneNumber,
      };

      await _apiClient.post<OtpResponse>(
        ApiConfig.pathAuth + '/otp',
        data: request,
        fromJson: (json) => OtpResponse.fromJson(json as Map<String, dynamic>),
      );

      _currentPhoneNumber = phoneNumber;
      _logger.i('OTP envoyé avec succès');
    } catch (e) {
      _logger.e('Erreur lors de la demande d\'OTP: $e');
      rethrow;
    }
  }

  /// Effectue l'inscription avec OTP
  /// 
  /// Génère une paire de clés ECDSA P-256 et les envoie au serveur
  Future<Compte> signup({
    required String phoneNumber,
    required String nom,
    required String otp,
  }) async {
    try {
      _logger.i('Inscription pour: $phoneNumber');

      // Générer la paire de clés
      _cryptoService = await CryptoService.generateKeyPair();
      final publicKeyJwk = await _cryptoService!.getPublicKeyAsJwk();

      final request = {
        'numero': phoneNumber,
        'nom': nom,
        'clePublique': publicKeyJwk,
        // Preuve : signature de {clePublique, nom, numero, objet: "inscription"}
        'preuve': _cryptoService!.signInscription(numero: phoneNumber, nom: nom),
        'codeOtp': otp,
      };

      final response = await _apiClient.post<InscriptionResponse>(
        ApiConfig.pathAuth,
        data: request,
        fromJson: (json) =>
            InscriptionResponse.fromJson(json as Map<String, dynamic>),
      );

      // Configurer le client avec les nouvelles informations
      _apiClient.configure(
        membreId: response.id,
        cryptoService: _cryptoService!,
      );

      _currentPhoneNumber = phoneNumber;

      _logger.i('Inscription réussie pour: ${response.id}');

      return Compte(
        id: response.id,
        numero: response.numero,
        nom: response.nom,
        niveau: response.niveau,
      );
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Récupère le profil du compte actuellement connecté
  Future<Compte> getMoi() async {
    try {
      final response = await _apiClient.get<Compte>(
        '${ApiConfig.pathAuth}/moi',
        fromJson: (json) => Compte.fromJson(json as Map<String, dynamic>),
      );

      _logger.i('Profil récupéré: ${response.id}');
      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du profil: $e');
      rethrow;
    }
  }

  /// Crée un contact de confiance pour la récupération de compte
  /// 
  /// Le contact reçoit un code par SMS qu'il devra confirmer
  Future<void> createContactConfiance({
    required String nom,
    required String numero,
  }) async {
    try {
      _logger.i('Création contact de confiance: $nom');

      final request = {
        'nom': nom,
        'numero': numero,
      };

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathAuth}/moi/contact-de-confiance',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Contact de confiance créé');
    } catch (e) {
      _logger.e('Erreur lors de la création du contact: $e');
      rethrow;
    }
  }

  /// Confirme l'accord du contact de confiance
  Future<void> confirmContactAgreement(String code) async {
    try {
      _logger.i('Confirmation contact de confiance');

      final request = {
        'code': code,
      };

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathAuth}/moi/contact-de-confiance/accord',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Contact confirmé');
    } catch (e) {
      _logger.e('Erreur lors de la confirmation: $e');
      rethrow;
    }
  }

  /// Crée un code secret pour la récupération de compte
  Future<void> createCodeSecret(String code) async {
    try {
      _logger.i('Création code secret');

      final request = {
        'code': code,
      };

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathAuth}/moi/code-secret',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Code secret créé');
    } catch (e) {
      _logger.e('Erreur lors de la création du code secret: $e');
      rethrow;
    }
  }

  /// Demande la récupération d'un compte depuis un nouvel appareil
  Future<String> requestRecovery({
    required String phoneNumber,
    required String codeSecret,
  }) async {
    try {
      _logger.i('Demande récupération compte');

      // Générer une nouvelle paire de clés pour le nouvel appareil
      _cryptoService = await CryptoService.generateKeyPair();
      final publicKeyJwk = await _cryptoService!.getPublicKeyAsJwk();

      final request = {
        'numero': phoneNumber,
        'clePublique': publicKeyJwk,
        'preuve': _cryptoService!.signRecuperation(numero: phoneNumber),
        'codeSecret': codeSecret,
      };

      await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.pathAuth}/recuperation',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.i('Récupération demandée');
      return phoneNumber;
    } catch (e) {
      _logger.e('Erreur lors de la demande de récupération: $e');
      rethrow;
    }
  }

  /// Redéfinit la session avec les informations d'un compte existant
  /// 
  /// Utilisé lors de la reconnexion après récupération
  Future<void> setCurrentSession({
    required String membreId,
    required CryptoService cryptoService,
  }) async {
    _apiClient.configure(
      membreId: membreId,
      cryptoService: cryptoService,
    );
    _cryptoService = cryptoService;
    _logger.i('Session définie pour: $membreId');
  }

  /// Déconnecte l'utilisateur
  void logout() {
    _apiClient.reset();
    _cryptoService?.dispose();
    _cryptoService = null;
    _currentPhoneNumber = null;
    _currentOtp = null;
    _logger.i('Déconnexion');
  }

  /// Retourne le numéro actuellement en cours d'authentification
  String? get currentPhoneNumber => _currentPhoneNumber;

  /// Retourne le service crypto actuel
  CryptoService? get cryptoService => _cryptoService;
}
