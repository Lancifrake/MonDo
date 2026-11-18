# MonDo - Frontend Mobile Flutter

Application mobile Flutter complètement intégrée avec le backend NestJS de MonDo (système de tontines numériques).

## 🚀 Démarrage Rapide (3 étapes)

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Générer le code (Freezed, JSON, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Adapter l'URL du backend et lancer
# Éditer .env et adapter API_URL si nécessaire
flutter run
```

**C'est tout!** L'app est prête à l'emploi. Zéro configuration supplémentaire nécessaire.

## 📚 Documentation

| Document | Contenu |
|----------|---------|
| **SETUP.md** | Guide complet d'installation et de configuration |
| **INTEGRATION_API.md** | Documentation complète des services et patterns |
| **ARCHITECTURE_OVERVIEW.md** | Architecture globale et flux de données |
| **CHECKLIST_DEPLOYMENT.md** | Vérifications avant déploiement |

## ✨ Ce qui est Inclus

### ✅ Services Implémentés

| Service | Endpoints | Statut |
|---------|-----------|--------|
| **AuthService** | OTP, Signup, Login, Recovery | ✅ Complet |
| **CerclesService** | Create, List, Join, Invite, Exchanges | ✅ Complet |
| **CotisationsService** | Declare, Confirm, List, State | ✅ Complet |
| **ScoreService** | Fetch member score | ✅ Complet |
| **LitigesService** | Open, List, Resolve | ✅ Complet |
| **NotificationsService** | Fetch, Mark read | ✅ Complet |

### ✅ Fonctionnalités

- ✅ **ECDSA P-256 Signing**: Toutes les requêtes signées automatiquement
- ✅ **Session Persistance**: Session sauvegardée et restaurée
- ✅ **State Management**: Riverpod pour la gestion d'état type-safe
- ✅ **Secure Storage**: Clés privées stockées en sécurité
- ✅ **Error Handling**: Gestion complète des erreurs API
- ✅ **Logging**: Logging détaillé pour le debugging
- ✅ **Modèles Freezed**: Modèles immutables auto-générés

## 🏗️ Architecture

L'architecture suit un pattern en couches:

```
UI (Flutter Widgets)
    ↓
Riverpod Providers (State Management)
    ↓
Services (Domain Logic)
    ↓
ApiClient (HTTP + Signatures)
    ↓
CryptoService (ECDSA P-256)
    ↓
Backend (NestJS)
```

Pour plus de détails, voir `ARCHITECTURE_OVERVIEW.md`.

## 💡 Exemples d'Utilisation

### Authentification

```dart
final authNotifier = ref.read(authStateProvider.notifier);

// Demander un code OTP
await authNotifier.requestOtp('237123456789');

// Finaliser l'inscription
await authNotifier.signup(
  phoneNumber: '237123456789',
  nom: 'Jean Dupont',
  otp: '123456',
);

// État de l'authentification
final authState = ref.watch(authStateProvider);
if (authState.isAuthenticated) {
  print('Connecté: ${authState.compte?.nom}');
}
```

### Lister les Cercles

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final cerclesAsync = ref.watch(mesCerclesProvider);
  
  return cerclesAsync.when(
    loading: () => CircularProgressIndicator(),
    error: (error, st) => Text('Erreur: $error'),
    data: (cercles) => ListView(
      children: cercles.map((c) => CercleCard(c)).toList(),
    ),
  );
}
```

### Déclarer un Paiement

```dart
final cotisationsService = ref.read(cotisationsServiceProvider);

final cotisation = await cotisationsService.declarerPaiement(
  cotisationId: 'cot-123',
  methode: 'mobile_money',
  referenceTransaction: 'TX-2024-001',
  signature: '...', // À signer avec la clé privée
);
```

Voir `lib/examples/` pour des exemples complets.

## 🔐 Sécurité

- ✅ Clés ECDSA P-256 générées localement
- ✅ Clés privées jamais envoyées au serveur
- ✅ Stockage sécurisé avec `flutter_secure_storage`
- ✅ Toutes les requêtes signées (sauf 4 routes publiques)
- ✅ Pas de secrets hardcodés

## 📱 Compatibilité

- ✅ Android 8+ (API 26+)
- ✅ iOS 11+
- ✅ Écrans 4.5" à 6.7"
- ✅ Portrait et Paysage

## 🛠️ Développement

### Build Runner (Code Generation)

```bash
# Mode watch (recommandé)
flutter pub run build_runner watch

# Build unique
flutter pub run build_runner build --delete-conflicting-outputs

# Nettoyer et régénérer
flutter pub run build_runner clean
flutter pub run build_runner build
```

### Linting et Formatage

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format .

# Vérifier avant de committer
flutter analyze && flutter format .
```

### Tester sur Appareil Réel

```bash
# Lister les appareils connectés
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>
```

## 📋 Fichiers Clés

```
lib/
├── config/api_config.dart           # Configuration API
├── models/api_models.dart           # Modèles Freezed
├── services/
│   ├── api_client.dart              # Client HTTP
│   ├── crypto_service.dart          # ECDSA P-256
│   ├── auth_service.dart            # Authentification
│   ├── cercles_service.dart         # Cercles
│   ├── cotisations_service.dart     # Cotisations
│   ├── score_service.dart           # Scores
│   ├── litiges_service.dart         # Litiges
│   ├── notifications_service.dart   # Notifications
│   └── local_storage_service.dart   # Stockage local
├── providers/
│   ├── auth_provider.dart           # Auth state
│   ├── cercles_provider.dart        # Cercles state
│   ├── cotisations_provider.dart    # Cotisations state
│   ├── score_provider.dart          # Score state
│   ├── litiges_provider.dart        # Litiges state
│   └── notifications_provider.dart  # Notifications state
└── examples/                        # Exemples de code
    ├── signup_screen_example.dart
    ├── cercles_list_example.dart
    └── app_initialization_example.dart
```

## 🚀 Déploiement

### Avant le Déploiement

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter format .
flutter build apk --release  # ou flutter build ios --release
```

### Configuration Production

Adapter `.env`:

```
API_URL=https://api.mondo.example.com
```

Consulter `CHECKLIST_DEPLOYMENT.md` pour la liste complète.

## 🐛 Troubleshooting

### "Erreur de génération de code"

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Erreur HTTP 401"

Vérifier que:
- La session est valide
- Les clés sont restaurées correctement
- Le backend est en cours d'exécution

### "Clé privée non trouvée"

```bash
# Nettoyer le stockage local
# L'app régénérera une nouvelle paire de clés à la prochaine authentification
```

Pour plus d'informations, voir `SETUP.md`.

## 📞 Support

1. Vérifier les logs (`flutter run` affiche les logs complets)
2. Consulter la documentation (voir **Documentation** ci-dessus)
3. Vérifier le fichier `.env`
4. Vérifier que le backend est accessible

## 📝 Notes de Version

### v1.0.0 (Current)

**Inclus:**
- Authentification complète (OTP, signup, recovery)
- Gestion des cercles
- Gestion des cotisations
- Score et litiges
- Notifications
- Stockage sécurisé
- Signatures ECDSA P-256

**À venir (v1.1):**
- Mode offline avec sync
- Push notifications (Firebase)
- Pagination avancée
- Filtrages

## ✅ Statut

**État**: ✅ **PRODUCTION READY**

- Tous les services implémentés
- Toutes les dépendances configurées
- Code généré et prêt
- Documentation complète
- Tests manuels effectués
- Sécurité vérifiée

**Prêt pour le déploiement.**

---

## 🎯 Points Importants

1. **Zéro Setup Supplémentaire**: Tout est pré-configuré
2. **Code Generation**: Exécuter `build_runner` une fois au démarrage
3. **Env File**: Adapter l'URL du backend si nécessaire
4. **Riverpod**: Utiliser toujours ConsumerWidget pour accéder aux services
5. **Sessions**: Automatiquement sauvegardées et restaurées
6. **Signatures**: Injectées automatiquement sur toutes les requêtes

## 📚 Lectures Recommandées

1. **SETUP.md** - Pour la configuration
2. **INTEGRATION_API.md** - Pour l'intégration des écrans
3. **ARCHITECTURE_OVERVIEW.md** - Pour comprendre le flux
4. **CHECKLIST_DEPLOYMENT.md** - Avant le déploiement

---

**Développement rapide et sûr** avec MonDo! 🚀
