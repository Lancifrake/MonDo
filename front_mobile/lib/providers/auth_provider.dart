import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import 'api_client_provider.dart';

/// État de l'authentification
class AuthState {
  final Compte? compte;
  final bool isLoading;
  final String? error;

  AuthState({
    this.compte,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => compte != null;

  AuthState copyWith({
    Compte? compte,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      compte: compte ?? this.compte,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Service d'authentification provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

/// État de l'authentification provider (StateNotifier)
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

/// Notifier pour gérer l'état de l'authentification
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(AuthState());

  /// Demande un code OTP
  Future<void> requestOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.requestOtp(phoneNumber);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Effectue l'inscription
  Future<void> signup({
    required String phoneNumber,
    required String nom,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final compte = await _authService.signup(
        phoneNumber: phoneNumber,
        nom: nom,
        otp: otp,
      );
      state = state.copyWith(
        isLoading: false,
        compte: compte,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Récupère le profil
  Future<void> fetchProfil() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final compte = await _authService.getMoi();
      state = state.copyWith(
        isLoading: false,
        compte: compte,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Crée un contact de confiance
  Future<void> createContactConfiance({
    required String nom,
    required String numero,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.createContactConfiance(
        nom: nom,
        numero: numero,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Confirme l'accord du contact
  Future<void> confirmContactAgreement(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.confirmContactAgreement(code);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Crée un code secret
  Future<void> createCodeSecret(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.createCodeSecret(code);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Demande la récupération du compte
  Future<void> requestRecovery({
    required String phoneNumber,
    required String codeSecret,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.requestRecovery(
        phoneNumber: phoneNumber,
        codeSecret: codeSecret,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Définit la session actuelle
  Future<void> setCurrentSession({
    required String membreId,
    required CryptoService cryptoService,
  }) async {
    await _authService.setCurrentSession(
      membreId: membreId,
      cryptoService: cryptoService,
    );
  }

  /// Déconnecte l'utilisateur
  void logout() {
    _authService.logout();
    state = AuthState();
  }
}
