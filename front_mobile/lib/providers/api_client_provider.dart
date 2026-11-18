import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Provider pour l'instance unique du client API
/// 
/// Ce provider est un Singleton qui fournit le client API à toute l'app
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
