import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'crypto_service.dart';

/// Exception levée lors d'erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

/// Client HTTP pour l'API MonDo avec signature ECDSA P-256
/// 
/// Gère :
/// - Toutes les requêtes HTTP (GET, POST, PUT, DELETE)
/// - Signature automatique des requêtes avec ECDSA P-256
/// - Injection des headers requis (x-mondo-*)
/// - Gestion des erreurs et retry
/// - Logging détaillé
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  
  String? _membreId;
  CryptoService? _cryptoService;
  
  // Routes publiques (non signées). Comparaison EXACTE : `/comptes/moi` est signée.
  static const List<String> _publicRoutes = [
    '/comptes/otp',
    '/comptes',
    '/comptes/recuperation',
    '/sante',
  ];
  static final RegExp _piecesRecuperation =
      RegExp(r'^/comptes/recuperation/[^/]+/pieces$');

  ApiClient() {
    _initializeDio();
  }

  /// Initialise l'instance Dio avec les configurations de base
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeoutSeconds),
        receiveTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
        sendTimeout: Duration(seconds: ApiConfig.requestTimeoutSeconds),
        headers: ApiConfig.getDefaultHeaders(),
      ),
    );

    // Ajouter un interceptor pour le logging
    _dio.interceptors.add(
      LoggingInterceptor(_logger),
    );

    // Ajouter un interceptor pour la gestion d'erreurs
    _dio.interceptors.add(
      ErrorInterceptor(_logger),
    );
  }

  /// Configure le client avec l'ID du membre et le service crypto
  /// 
  /// Doit être appelé après l'authentification
  void configure({
    required String membreId,
    required CryptoService cryptoService,
  }) {
    _membreId = membreId;
    _cryptoService = cryptoService;
    _logger.i('Client API configuré pour le membre: $membreId');
  }

  /// Compte connecté et sa clé, pour signer règlements et engagements.
  String? get membreId => _membreId;
  CryptoService? get cryptoService => _cryptoService;

  /// Réinitialise le client (déconnexion)
  void reset() {
    _membreId = null;
    _cryptoService = null;
    _logger.i('Client API réinitialisé');
  }

  /// Effectue une requête GET
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _request<T>(
        method: 'GET',
        path: path,
        queryParameters: queryParameters,
        fromJson: fromJson,
      );
      return response;
    } catch (e) {
      _logger.e('Erreur GET $path: $e');
      rethrow;
    }
  }

  /// Effectue une requête POST
  Future<T> post<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _request<T>(
        method: 'POST',
        path: path,
        data: data,
        queryParameters: queryParameters,
        fromJson: fromJson,
      );
      return response;
    } catch (e) {
      _logger.e('Erreur POST $path: $e');
      rethrow;
    }
  }

  /// Effectue une requête PUT
  Future<T> put<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _request<T>(
        method: 'PUT',
        path: path,
        data: data,
        queryParameters: queryParameters,
        fromJson: fromJson,
      );
      return response;
    } catch (e) {
      _logger.e('Erreur PUT $path: $e');
      rethrow;
    }
  }

  /// Effectue une requête DELETE
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _request<T>(
        method: 'DELETE',
        path: path,
        queryParameters: queryParameters,
        fromJson: fromJson,
      );
      return response;
    } catch (e) {
      _logger.e('Erreur DELETE $path: $e');
      rethrow;
    }
  }

  /// Effectue une requête HTTP générique
  /// 
  /// Cette méthode :
  /// 1. Crée l'URL complète avec les query parameters
  /// 2. Ajoute les headers standards
  /// 3. Signe la requête si nécessaire (routes non publiques)
  /// 4. Effectue la requête
  /// 5. Parse la réponse
  Future<T> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      // Construire l'URL complète pour le logging et la signature
      final fullPath = _buildFullPath(path, queryParameters);

      // Préparer les headers
      final headers = ApiConfig.getDefaultHeaders();

      // Ajouter les headers de signature si ce n'est pas une route publique
      if (!_isPublicRoute(path)) {
        if (_membreId == null || _cryptoService == null) {
          throw ApiException(
            message: 'Authentification requise pour $path',
          );
        }

        // Créer les headers de signature
        final timestamp = CryptoService.horodatage();
        final signature = await _cryptoService!.signRequest(
          method: method,
          path: fullPath,
          timestamp: timestamp,
          body: data,
        );

        headers['x-mondo-membre'] = _membreId!;
        headers['x-mondo-horodatage'] = timestamp;
        headers['x-mondo-signature'] = signature;
      }

      // Effectuer la requête sur le chemin EXACT qui a été signé (requête comprise)
      final response = await _dio.request(
        fullPath,
        data: data != null && data.isNotEmpty ? jsonEncode(data) : null,
        options: Options(
          method: method,
          headers: headers,
        ),
      );

      // Parser la réponse
      return fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Erreur Dio: ${e.message}', error: e);
      final corps = e.response?.data;
      final duServeur = corps is Map ? corps['message'] : null;
      throw ApiException(
        message: duServeur is String
            ? duServeur
            : duServeur is List
                ? duServeur.join(', ')
                : (e.message ?? 'Erreur réseau'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      _logger.e('Erreur inattendue: $e');
      throw ApiException(
        message: 'Erreur inattendue: $e',
        originalError: e,
      );
    }
  }

  /// Construit le chemin complet avec les query parameters
  /// 
  /// Utilisé pour la signature et le logging
  String _buildFullPath(
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }

    final queryString = queryParameters.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$path?$queryString';
  }

  /// Vérifie si une route est publique (n'a pas besoin de signature)
  static bool _isPublicRoute(String path) {
    final sansRequete = path.split('?').first;
    return _publicRoutes.contains(sansRequete) ||
        _piecesRecuperation.hasMatch(sansRequete);
  }

  /// Dispose du client
  void dispose() {
    _cryptoService?.dispose();
    _dio.close();
    _logger.i('ApiClient disposé');
  }
}

/// Interceptor pour le logging des requêtes
class LoggingInterceptor extends Interceptor {
  final Logger logger;

  LoggingInterceptor(this.logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('''
    ➜ REQUÊTE
    Méthode: ${options.method}
    URL: ${options.baseUrl}${options.path}
    Headers: ${options.headers}
    Données: ${options.data}
    ''');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('''
    ✓ RÉPONSE
    Statut: ${response.statusCode}
    URL: ${response.requestOptions.path}
    Données: ${response.data}
    ''');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('''
    ✗ ERREUR
    Message: ${err.message}
    Statut: ${err.response?.statusCode}
    URL: ${err.requestOptions.path}
    Réponse: ${err.response?.data}
    ''');
    handler.next(err);
  }
}

/// Interceptor pour la gestion d'erreurs globale
class ErrorInterceptor extends Interceptor {
  final Logger logger;

  ErrorInterceptor(this.logger);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Ajouter ici la logique de retry ou de gestion d'erreurs globale si nécessaire
    handler.next(err);
  }
}
