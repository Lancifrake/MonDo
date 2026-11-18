/// Configuration centralisée de l'API MonDo
/// 
/// Cette classe contient :
/// - L'URL de base du backend
/// - Les timeouts
/// - Les chemins d'accès aux ressources
class ApiConfig {
  /// Adresse du serveur. Par défaut l'instance de démonstration (Render, s'endort
  /// après 15 min : le premier appel peut prendre 30 s). Pour un serveur local :
  /// flutter run --dart-define=API_URL=http://127.0.0.1:3000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://mondo-serveur-demo.onrender.com',
  );

  /// Délai d'expiration des requêtes en secondes
  static const int requestTimeoutSeconds = 60;

  /// Délai d'expiration de la connexion en secondes
  static const int connectTimeoutSeconds = 60;

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
