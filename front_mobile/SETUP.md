# Configuration Complète du Frontend Mobile MonDo

Ce guide vous accompagne dans la configuration de l'environnement et le démarrage de l'application.

## 🚀 Quick Start (5 minutes)

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Générer le code (Freezed, JSON, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Configurer l'API (adapter l'URL si nécessaire)
cp .env.example .env
# Éditer .env et adapter API_URL si besoin

# 4. Lancer l'application
flutter run
```

## 📦 Dépendances Requises

### Pour le Développement

- **Flutter**: 3.12.0+
- **Dart**: 3.12.0+
- **Android Studio** ou **Xcode** (selon la plateforme)

### Packages Flutter

Tous les packages sont déjà configurés dans `pubspec.yaml`:

| Package | Rôle |
|---------|------|
| `dio` | Client HTTP |
| `riverpod` | State Management |
| `cryptography` | Signatures ECDSA P-256 |
| `freezed_annotation` | Modèles immutables |
| `json_annotation` | Sérialisation JSON |
| `flutter_secure_storage` | Stockage sécurisé des clés |
| `shared_preferences` | Stockage de données publiques |
| `logger` | Logging |
| `uuid` | Génération d'IDs |
| `google_fonts` | Polices personnalisées |

## 🛠️ Installation Détaillée

### Étape 1: Cloner le Projet

```bash
git clone <repo-url>
cd front_mobile
```

### Étape 2: Installer les Dépendances Flutter

```bash
flutter pub get
```

Cette commande télécharge tous les packages lisps dans `pubspec.yaml`.

### Étape 3: Code Generation

Le projet utilise plusieurs outils de code generation qui **DOIVENT** être exécutés:

#### Option A: Build unique (une seule fois)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Option B: Build en Watch Mode (recommandé pendant le dev)

```bash
flutter pub run build_runner watch
```

Le Watch Mode regénère automatiquement le code quand vous modifiez les fichiers.

**Fichiers générés:**
- `lib/models/api_models.freezed.dart` - Modèles Freezed
- `lib/models/api_models.g.dart` - Sérialisation JSON

⚠️ **Important**: Ne jamais éditer les fichiers `.freezed.dart` et `.g.dart` - ils sont générés automatiquement.

### Étape 4: Configuration de l'API

#### Créer le fichier `.env`

```bash
cp .env.example .env
```

#### Éditer `.env` selon votre environnement

**Pour le développement local:**
```
API_URL=http://localhost:3000
```

**Pour une IP locale (sur le même réseau):**
```
API_URL=http://192.168.1.100:3000
```

**Pour la production:**
```
API_URL=https://api.mondo.example.com
```

### Étape 5: Démarrer l'Application

#### Android

```bash
flutter run
```

#### iOS

```bash
# Si première fois
cd ios
pod install
cd ..

flutter run
```

#### Web (optionnel)

```bash
flutter run -d chrome
```

## 🗂️ Structure du Projet

```
lib/
├── config/
│   └── api_config.dart              # Configuration API centralisée
│
├── models/
│   └── api_models.dart              # Modèles Freezed (auto-généré)
│
├── services/
│   ├── api_client.dart              # Client HTTP avec signatures
│   ├── crypto_service.dart          # ECDSA P-256
│   ├── auth_service.dart            # Authentification
│   ├── cercles_service.dart         # Cercles/Tontines
│   ├── cotisations_service.dart     # Cotisations/Paiements
│   ├── score_service.dart           # Scores de confiance
│   ├── litiges_service.dart         # Litiges/Arbitrages
│   ├── notifications_service.dart   # Notifications
│   └── local_storage_service.dart   # Persistance locale
│
├── providers/
│   ├── api_client_provider.dart
│   ├── auth_provider.dart
│   ├── cercles_provider.dart
│   ├── cotisations_provider.dart
│   ├── score_provider.dart
│   ├── litiges_provider.dart
│   ├── notifications_provider.dart
│   └── storage_provider.dart
│
└── examples/
    ├── signup_screen_example.dart
    ├── cercles_list_example.dart
    └── app_initialization_example.dart
```

## 🔗 Intégration aux Écrans Existants

### Fichiers de Référence

- **Exemple d'écran d'inscription**: `lib/examples/signup_screen_example.dart`
- **Exemple de liste de cercles**: `lib/examples/cercles_list_example.dart`
- **Initialisation de l'app**: `lib/examples/app_initialization_example.dart`

### Guide Rapide

#### 1. Importer Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

#### 2. Utiliser ConsumerWidget/ConsumerStatefulWidget

Au lieu de `StatelessWidget` ou `StatefulWidget`:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accès aux providers ici
    return Scaffold(...);
  }
}
```

#### 3. Accéder aux Services

```dart
// Regarder un provider (écoute les changements)
final cerclesAsync = ref.watch(mesCerclesProvider);

// Lire un provider sans l'écouter
final authService = ref.read(authServiceProvider);

// Rafraîchir un provider
ref.refresh(mesCerclesProvider);
```

#### 4. Gérer l'État Asynchrone

```dart
cerclesAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, st) => Text('Erreur: $error'),
  data: (cercles) => ListView(
    children: cercles.map((c) => CercleCard(c)).toList(),
  ),
)
```

## 🧪 Tester l'Intégration

### 1. Vérifier le Logging

Les logs détaillés s'affichent dans la console:

```
I/flutter: ➜ REQUÊTE
I/flutter: Méthode: POST
I/flutter: URL: http://localhost:3000/comptes/otp
I/flutter: ✓ RÉPONSE
I/flutter: Statut: 200
```

### 2. Tester avec le Backend Local

```bash
# Terminal 1: Backend
cd backend
npm run start

# Terminal 2: Mobile
cd front_mobile
flutter run
```

### 3. Tester l'Authentification Complète

1. Ouvrir l'app
2. Cliquer sur "S'inscrire"
3. Entrer un numéro de téléphone
4. Attendre le code OTP (en dev, peut être en log)
5. Entrer le code
6. Remplir le formulaire
7. Vérifier que l'authentification réussit

## ⚠️ Problèmes Courants

### "Clé publique non disponible"

**Cause**: `CryptoService` n'a pas été initialisé

**Solution**: S'assurer que `AuthService.signup()` a été appelé avec succès

### "Erreur de signature: `_privateKey` est null"

**Cause**: `ApiClient` n'a pas été configuré avec le `CryptoService`

**Solution**: Appeler `apiClient.configure()` après l'authentification

### "Build Runner ne génère pas les fichiers"

**Solution**: 
```bash
# Nettoyer et régénérer
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Erreur HTTP 400 ou 401"

**Cause potentielle**: URL du backend incorrecte

**Solution**: Vérifier le fichier `.env` et relancer l'app

### "Erreur SSL sur HTTPS"

**Cause**: Certificat auto-signé

**Solution** (dev uniquement):
```dart
// Dans api_client.dart, ajouter avant le Dio:
(_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
    (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
```

## 📚 Documentation

- **Guide d'intégration complet**: `INTEGRATION_API.md`
- **API Backend**: `../docs/conception/api.md`
- **Cahier des charges**: `../docs/cadrage/`

## 🔐 Sécurité

### Clés Privées

Les clés privées sont:
- ✅ Générées localement dans l'app
- ✅ Jamais envoyées au serveur
- ✅ Stockées en sécurité avec `flutter_secure_storage`
- ✅ Automatiquement restaurées après redémarrage

### Requêtes Signées

- ✅ Toutes les requêtes sont automatiquement signées avec ECDSA P-256
- ✅ Les signatures sont vérifiées côté serveur
- ✅ Les 4 routes publiques (OTP, signup, recovery, health) ne nécessitent pas de signature

## 📝 Logs et Debugging

### Activer les logs détaillés

Les logs sont affichés automatiquement avec le préfixe `I/flutter:`

### Accéder à l'inspecteur Riverpod

Dans la console:
```
flutter run --enable-dart-dev-service
```

Puis visiter: `http://localhost:8080` (si disponible)

## 🚀 Déploiement

### Avant de Déployer

```bash
# 1. Nettoyer le projet
flutter clean

# 2. Réinstaller les dépendances
flutter pub get

# 3. Régénérer le code
flutter pub run build_runner build

# 4. Tester en mode release
flutter run --release
```

### Build Android APK

```bash
flutter build apk --release
# Fichier généré: build/app/outputs/apk/release/app-release.apk
```

### Build iOS

```bash
flutter build ios --release
# Fichier généré: build/ios/iphoneos/Runner.app
```

## 📞 Support

En cas de problème:

1. Vérifier les logs (`flutter run` affiche les logs complets)
2. Consulter `INTEGRATION_API.md`
3. Vérifier que le backend est en cours d'exécution
4. Vérifier l'URL de l'API dans `.env`

## ✅ Checklist de Finalisation

- [ ] Dépendances installées (`flutter pub get`)
- [ ] Code généré (`flutter pub run build_runner build`)
- [ ] Fichier `.env` créé et configuré
- [ ] Backend en cours d'exécution
- [ ] App démarre sans erreur (`flutter run`)
- [ ] Authentification testée
- [ ] Écrans existants intégrés aux providers
- [ ] Stockage local testé (session persistée)
- [ ] Erreurs gérées correctement
- [ ] Logs visibles en cas de problème

---

**Prêt à développer!** 🎉

Le prochain développeur n'aura besoin que de:
1. Installer Flutter
2. Cloner le repo
3. Exécuter `flutter pub get`
4. Exécuter `flutter pub run build_runner build`
5. Adapter `.env`
6. Lancer `flutter run`
