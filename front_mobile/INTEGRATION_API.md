# Intégration API MonDo - Guide Complet

Ce document décrit comment utiliser l'intégration API complète pour l'application mobile MonDo.

## 📋 Table des matières

1. [Setup Initial](#setup-initial)
2. [Architecture](#architecture)
3. [Services Disponibles](#services-disponibles)
4. [État Management (Riverpod)](#état-management-riverpod)
5. [Authentification](#authentification)
6. [Utilisation par Module](#utilisation-par-module)
7. [Gestion d'Erreurs](#gestion-derreurs)
8. [Testing](#testing)

## Setup Initial

### 1. Dépendances

Les dépendances sont déjà configurées dans `pubspec.yaml`:

```bash
flutter pub get
```

### 2. Code Generation

Générer le code Freezed et JSON serializable:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Ou en mode watch (recommandé pendant le développement):

```bash
flutter pub run build_runner watch
```

### 3. Configuration de l'API

Créer un fichier `.env` depuis `.env.example`:

```bash
cp .env.example .env
```

Adapter l'URL du backend selon l'environnement:

```
API_URL=http://192.168.1.X:3000  # Pour le développement local
API_URL=https://api.mondo.example.com  # Pour la production
```

## Architecture

### Couches

```
UI Screens
    ↓
Riverpod Providers (State Management)
    ↓
Services (Domain Logic)
    ↓
ApiClient (HTTP)
    ↓
CryptoService (ECDSA P-256)
    ↓
LocalStorageService (Persistence)
```

### Fichiers Clés

```
lib/
├── config/
│   └── api_config.dart           # Configuration centralisée
├── models/
│   └── api_models.dart            # DTOs Freezed
├── services/
│   ├── api_client.dart            # Client HTTP Dio
│   ├── crypto_service.dart        # Signatures ECDSA P-256
│   ├── auth_service.dart          # Authentification
│   ├── cercles_service.dart       # Gestion des cercles
│   ├── cotisations_service.dart   # Gestion des cotisations
│   ├── score_service.dart         # Scores de confiance
│   ├── litiges_service.dart       # Gestion des litiges
│   ├── notifications_service.dart # Notifications
│   └── local_storage_service.dart # Persistance locale
└── providers/
    ├── api_client_provider.dart
    ├── auth_provider.dart
    ├── cercles_provider.dart
    ├── cotisations_provider.dart
    ├── score_provider.dart
    ├── litiges_provider.dart
    ├── notifications_provider.dart
    └── storage_provider.dart
```

## Services Disponibles

### AuthService

Gère l'authentification et la session utilisateur.

**Endpoints:**
- `POST /comptes/otp` - Demander un code OTP
- `POST /comptes` - S'inscrire
- `GET /comptes/moi` - Récupérer le profil
- `POST /comptes/moi/contact-de-confiance` - Ajouter un contact
- `POST /comptes/moi/code-secret` - Créer un code secret
- `POST /comptes/recuperation` - Récupérer un compte

### CerclesService

Gère la création et la gestion des cercles (tontines).

**Endpoints:**
- `GET /cercles/bareme` - Calculer le barème des frais
- `POST /cercles` - Créer un cercle
- `GET /cercles` - Lister mes cercles
- `GET /cercles/catalogue` - Consulter le catalogue
- `GET /cercles/:id` - Détails d'un cercle
- `POST /cercles/:id/adhesions` - Adhérer
- `POST /cercles/:id/invitations` - Inviter
- `POST /cercles/:id/depart` - Quitter
- `GET /cercles/:id/registre` - Consulter le registre
- `GET /cercles/:id/echanges` - Voir les échanges
- `POST /cercles/:id/echanges` - Proposer un échange

### CotisationsService

Gère les cotisations et les paiements.

**Endpoints:**
- `GET /cotisations` - Lister mes cotisations
- `GET /cotisations/:id` - Détails
- `POST /cotisations/:id/paiement` - Déclarer un paiement
- `POST /cotisations/:id/confirmation` - Confirmer
- `GET /cotisations/cercles/:id/etat` - État par cercle

### ScoreService

Consulte les scores de confiance.

**Endpoints:**
- `GET /score/:membreId` - Score d'un membre
- `GET /score/moi` - Mon score

### LitigesService

Gère les litiges et les arbitrages.

**Endpoints:**
- `POST /litiges` - Ouvrir un litige
- `GET /litiges/miens` - Mes litiges
- `GET /litiges/:id` - Détails
- `POST /litiges/:id/decision` - Soumettre une décision
- `GET /litiges/en-attente` - Arbitrages en attente

### NotificationsService

Gère les notifications.

**Endpoints:**
- `GET /notifications` - Lister
- `POST /notifications/:id/lue` - Marquer comme lue
- `GET /notifications/non-lues/count` - Compter les non-lues

### LocalStorageService

Stockage local sécurisé pour les clés et sessions.

## État Management (Riverpod)

Tous les services utilisent **Riverpod** pour la gestion d'état.

### Patterns Utilisés

#### 1. FutureProvider (Données asynchrones)

```dart
final mesCerclesProvider = FutureProvider<List<ResumeCercle>>((ref) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getMesCercles();
});
```

Usage dans un Widget:

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

#### 2. StateNotifierProvider (État mutable)

```dart
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});
```

Usage:

```dart
ref.read(authStateProvider.notifier).signup(
  phoneNumber: '237123456789',
  nom: 'Jean',
  otp: '123456',
);
```

#### 3. StateProvider (État simple)

```dart
final cerclesRefreshProvider = StateProvider<int>((ref) => 0);
```

Usage pour rafraîchir:

```dart
ref.read(cerclesRefreshProvider.notifier).state++;
```

### Rafraîchir les Données

Pour forcer un rafraîchissement:

```dart
ref.refresh(mesCerclesProvider);
// ou
ref.read(cerclesRefreshProvider.notifier).state++;
```

## Authentification

### Flux d'Inscription

```dart
final authNotifier = ref.read(authStateProvider.notifier);

// 1. Demander OTP
await authNotifier.requestOtp('237123456789');

// 2. Attendre le SMS du code OTP
// L'utilisateur entre le code reçu par SMS

// 3. S'inscrire
await authNotifier.signup(
  phoneNumber: '237123456789',
  nom: 'Jean Dupont',
  otp: '123456',
);

// La paire de clés ECDSA P-256 est générée automatiquement
// et la session est sauvegardée
```

### Flux de Récupération de Compte

```dart
// 1. Demander la récupération
await authNotifier.requestRecovery(
  phoneNumber: '237123456789',
  codeSecret: 'mon-code-secret',
);

// 2. Les clés sont restaurées et une nouvelle paire est créée
// pour le nouvel appareil
```

### Persistance de Session

La session est automatiquement sauvegardée après l'authentification et restaurée au démarrage.

```dart
// Au démarrage de l'app
final hasSession = ref.watch(hasSessionProvider);
final savedSession = ref.watch(savedSessionProvider);

if (hasSession) {
  // Utilisateur déjà connecté
  // Naviguer vers l'écran d'accueil
}
```

### Déconnexion

```dart
ref.read(authStateProvider.notifier).logout();
```

## Utilisation par Module

### 1. Création de Cercle

```dart
// Dans un screen
final cerclesService = ref.read(cerclesServiceProvider);

// Créer le cercle
final cercle = await cerclesService.createCercle(
  nom: 'Tontine des Amis',
  description: 'Tontine de quartier',
  montant: 50000, // 50 000 francs
  frequence: 'mensuelle',
  nombreMembres: 10,
  isPrivate: false,
  signature: '...', // À signer avec la clé privée
  scoreMinimum: 50,
);

// Rafraîchir la liste
ref.refresh(mesCerclesProvider);
```

### 2. Déclarer un Paiement

```dart
final cotisationsService = ref.read(cotisationsServiceProvider);

final cotisation = await cotisationsService.declarerPaiement(
  cotisationId: 'cot-123',
  methode: 'mobile_money',
  referenceTransaction: 'TX-2024-001',
  signature: '...', // À signer
);

// Rafraîchir
ref.refresh(mesCotisationsProvider);
```

### 3. Consulter le Score

```dart
final scoreAsync = ref.watch(monScoreProvider);

scoreAsync.whenData((score) {
  print('Mon score: ${score.score}');
  print('Accès premières places: ${score.premieresPlacesFermees == false}');
});
```

### 4. Ouvrir un Litige

```dart
final litigesService = ref.read(litigesServiceProvider);

final litige = await litigesService.ouvrirLitige(
  cotisationId: 'cot-123',
  motif: 'Paiement non confirmé depuis 7 jours',
  signature: '...', // À signer
);

// Rafraîchir
ref.refresh(mesLitigesProvider);
```

### 5. Notifications

```dart
// Lister les notifications
final notificationsAsync = ref.watch(notificationsProvider);

// Marquer une comme lue
final notificationsService = ref.read(notificationsServiceProvider);
await notificationsService.marquerCommeEue(notifId);

// Rafraîchir
ref.refresh(notificationsProvider);

// Compter les non-lues
final countAsync = ref.watch(comptNotificationsNonLuesProvider);
```

## Gestion d'Erreurs

Tous les services lancent des `ApiException` avec des détails.

### Pattern de Gestion

```dart
try {
  await authNotifier.signup(...);
} on ApiException catch (e) {
  // e.message: Message d'erreur
  // e.statusCode: Code HTTP (400, 401, 403, etc.)
  // e.originalError: Erreur originale Dio
  
  if (e.statusCode == 400) {
    // Erreur de validation
  } else if (e.statusCode == 401) {
    // Non authentifié
  } else if (e.statusCode == 403) {
    // Pas d'accès
  } else if (e.statusCode == 423) {
    // Ressource verrouillée
  } else if (e.statusCode == 429) {
    // Rate limiting
  }
} catch (e) {
  // Erreur inattendue
}
```

### Codes HTTP Gérés

| Code | Signification |
|------|---------------|
| 200 | Succès |
| 400 | Validation échouée |
| 401 | Non authentifié |
| 403 | Pas d'accès |
| 404 | Non trouvé |
| 423 | Ressource verrouillée |
| 429 | Rate limiting |
| 500 | Erreur serveur |

## Testing

### Test d'un Service

```dart
test('AuthService.signup envoie une requête valide', () async {
  final mockClient = MockApiClient();
  final authService = AuthService(mockClient);
  
  await authService.signup(
    phoneNumber: '237123456789',
    nom: 'Jean',
    otp: '123456',
  );
  
  verify(mockClient.post(
    '/comptes',
    data: any,
  )).called(1);
});
```

### Test d'un Provider

```dart
test('mesCerclesProvider récupère la liste', (WidgetTester tester) async {
  final container = ProviderContainer();
  
  final cercles = await container.read(mesCerclesProvider.future);
  
  expect(cercles, isNotEmpty);
});
```

## Points Importants

1. **Signatures ECDSA P-256**: Tous les endpoints sauf 4 routes publiques exigent une signature. Le `ApiClient` l'ajoute automatiquement.

2. **Headers Automatiques**: Les headers `x-mondo-*` sont injectés automatiquement par le `ApiClient`.

3. **Session Persistante**: La session est sauvegardée localement et restaurée au démarrage. La clé privée est stockée en sécurité.

4. **Code Generation**: Les modèles Freezed doivent être générés avec `build_runner`. Ne jamais éditer les fichiers `.freezed.dart` et `.g.dart`.

5. **Logging**: Tous les services utilisent `Logger` pour le debugging. Vérifier les logs en cas d'erreur.

6. **Riverpod**: Toujours utiliser les providers Riverpod dans les widgets, jamais créer directement les services.

## Ressources

- [Documentation Dio](https://pub.dev/packages/dio)
- [Documentation Riverpod](https://riverpod.dev)
- [Documentation Cryptography](https://pub.dev/packages/cryptography)
- [API MonDo Backend](../docs/conception/api.md)
