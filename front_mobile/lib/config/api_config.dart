/// Configuration centralisée de l'API MonDo
/// 
/// Cette classe contient :
/// - L'URL de base du backend
/// - Les timeouts
/// - Les chemins d'accès aux ressources
class ApiConfig {
  /// URL de base du backend - À ADAPTER selon l'environnement
  /// 
  /// Pour le développement local, utilisez :
  /// http://localhost:3000 ou http://192.168.1.X:3000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Délai d'expiration des requêtes en secondes
  static const int requestTimeoutSeconds = 30;

  /// Délai d'expiration de la connexion en secondes
  static const int connectTimeoutSeconds = 15;

  /// Chemins des endpoints principaux
  static const String pathAuth = '/comptes';
  static const String pathCercles = '/cercles';
  static const String pathCotisations = '/cotisations';
  static const String pathScore = '/score';
  static const String pathLitiges = '/litiges';
  static const String pathNotifications = '/notifications';
  static const String pathHealth = '/sante';

  /// Headers standards pour toutes les requêtes
  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
