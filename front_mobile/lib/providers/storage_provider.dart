import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

/// Provider pour le service de stockage local
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Provider pour vérifier s'il existe une session sauvegardée
final hasSessionProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(localStorageProvider);
  return storage.hasSession();
});

/// Provider pour récupérer la session sauvegardée
final savedSessionProvider = FutureProvider<SavedSession?>((ref) async {
  final storage = ref.watch(localStorageProvider);
  return storage.getSession();
});
