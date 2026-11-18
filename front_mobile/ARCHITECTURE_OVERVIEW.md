# Architecture de l'Intégration API MonDo

Vue d'ensemble complète de l'architecture et du flux de données.

## 📊 Flux de Données Global

```
┌─────────────────────────────────────────────────────────┐
│                   UI Screens (Flutter)                  │
│  (SignupScreen, CerclesListScreen, CotisationsScreen)  │
└─────────────────────────┬───────────────────────────────┘
                          │ Riverpod Providers
                          ↓
┌─────────────────────────────────────────────────────────┐
│              State Management (Riverpod)                 │
│  (authProvider, cerclesProvider, cotisationsProvider)   │
└─────────────────────────┬───────────────────────────────┘
                          │ ref.watch/ref.read
                          ↓
┌─────────────────────────────────────────────────────────┐
│            Services Métier (Service Layer)              │
│  (AuthService, CerclesService, CotisationsService)      │
└─────────────────────────┬───────────────────────────────┘
                          │ Appels de méthodes
                          ↓
┌─────────────────────────────────────────────────────────┐
│          Client HTTP (ApiClient with Dio)               │
│  - Injection des signatures ECDSA P-256                 │
│  - Headers x-mondo-*                                     │
│  - Gestion des erreurs et retry                          │
└─────────────────────────┬───────────────────────────────┘
                          │ HTTP Requests/Responses
                          ↓
┌─────────────────────────────────────────────────────────┐
│          Crypto Service (ECDSA P-256)                   │
│  - Signature de requêtes                                 │
│  - Gestion de clés                                       │
└─────────────────────────┬───────────────────────────────┘
                          │ Signing
                          ↓
┌─────────────────────────────────────────────────────────┐
│         Backend NestJS (localhost:3000)                  │
│  - /comptes, /cercles, /cotisations, etc.               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│     Local Storage (Sécurisé & Public)                    │
│  - flutter_secure_storage: clés privées                  │
│  - SharedPreferences: sessions publiques                 │
└─────────────────────────────────────────────────────────┘
```

## 🏗️ Architecture en Couches

### Couche 1: UI (Flutter Widgets)

**Fichiers**: `screens/`, `widgets/`

Widgets qui affichent les données et capturent les interactions utilisateur.

```dart
ConsumerWidget build(BuildContext context, WidgetRef ref) {
  final dataAsync = ref.watch(someProvider);
  return dataAsync.when(
    loading: () => ...,
    error: (e, st) => ...,
    data: (data) => ...,
  );
}
```

### Couche 2: State Management (Riverpod Providers)

**Fichiers**: `lib/providers/*.dart`

Gère l'état de l'app et coordonne les appels aux services.

```dart
final mesCerclesProvider = FutureProvider<List<ResumeCercle>>((ref) async {
  final cerclesService = ref.watch(cerclesServiceProvider);
  return cerclesService.getMesCercles();
});
```

**Types de providers:**
- `FutureProvider`: Données asynchrones (API calls)
- `StateNotifierProvider`: État mutable (formulaires)
- `StateProvider`: État simple (flags)

### Couche 3: Services (Domain Logic)

**Fichiers**: `lib/services/*.dart`

Encapsule la logique métier pour chaque domaine.

```dart
class CerclesService {
  Future<List<Cercle>> getMesCercles() async {
    return _apiClient.get('/cercles', ...);
  }
}
```

**Services principaux:**
- `AuthService`: Authentification
- `CerclesService`: Gestion des cercles
- `CotisationsService`: Paiements
- `ScoreService`: Scores
- `LitigesService`: Litiges
- `NotificationsService`: Notifications

### Couche 4: API Client (HTTP)

**Fichier**: `lib/services/api_client.dart`

Client HTTP avec signature automatique des requêtes.

```dart
// Injecte automatiquement:
// - Signatures ECDSA P-256
// - Headers x-mondo-*
// - Gestion des erreurs
final response = await apiClient.post('/cercles', data: {...});
```

### Couche 5: Cryptographie (ECDSA P-256)

**Fichier**: `lib/services/crypto_service.dart`

Gère les paires de clés et la signature des requêtes.

```dart
final signature = await cryptoService.signRequest(
  method: 'POST',
  path: '/cercles',
  timestamp: '2024-11-18T10:00:00Z',
  body: {...},
);
```

### Couche 6: Modèles (Freezed)

**Fichier**: `lib/models/api_models.dart`

Modèles de données immutables avec sérialisation JSON automatique.

```dart
@freezed
class Compte with _$Compte {
  const factory Compte({
    required String id,
    required String nom,
    required int niveau,
  }) = _Compte;

  factory Compte.fromJson(Map<String, dynamic> json) =>
      _$CompteFromJson(json);
}
```

### Couche 7: Persistance Locale

**Fichier**: `lib/services/local_storage_service.dart`

Stockage sécurisé des sessions et clés.

```dart
// Sauvegarder la session après authentification
await storage.saveSession(
  membreId: 'mem-123',
  phoneNumber: '237123456789',
  cryptoService: cryptoService,
);

// Restaurer au démarrage
final savedSession = await storage.getSession();
```

## 🔄 Cycle de Vie des Requêtes

### Exemple: Récupérer la liste des cercles

```
1. UI: ref.watch(mesCerclesProvider)
   ↓
2. Provider: FutureProvider attend et observe cerclesService.getMesCercles()
   ↓
3. Service: CerclesService.getMesCercles() appelle apiClient.get(...)
   ↓
4. ApiClient:
   a) Construit l'URL complète: /cercles
   b) Prépare les headers
   c) Vérifie si la route nécessite une signature (non publique)
   d) Signe la requête avec CryptoService
   e) Ajoute les headers x-mondo-*
   f) Effectue la requête HTTP avec Dio
   ↓
5. CryptoService:
   a) Signe le JSON canonique {methode, chemin, horodatage, corps}
   b) Retourne la signature en base64
   ↓
6. Backend:
   a) Valide la signature avec la clé publique
   b) Vérifie les headers
   c) Retourne les données ou une erreur
   ↓
7. ApiClient:
   a) Parse la réponse
   b) Retourne les données typées
   c) Ou lance une ApiException
   ↓
8. Service:
   a) Retourne la liste de Cercle (ou lance l'exception)
   ↓
9. Provider:
   a) Complète le FutureProvider avec les données
   b) Les widgets observants sont mis à jour
   ↓
10. UI:
    a) Affiche la liste avec les cercles
```

## 🔐 Flux d'Authentification

```
┌─────────────────┐
│   Utilisateur   │
└────────┬────────┘
         │
         ↓
┌──────────────────────┐
│  Demander OTP        │
│  POST /comptes/otp   │
└────────┬─────────────┘
         │ No signature (public route)
         ↓
    ┌────────────┐
    │ Reçoit OTP │
    │ par SMS    │
    └────┬───────┘
         │
         ↓
┌──────────────────────────────────┐
│  CryptoService.generateKeyPair() │
│  Génère paire ECDSA P-256        │
└────────┬───────────────────────┬─┘
         │                       │
    ┌────▼────┐            ┌────▼─────┐
    │ Private │            │  Public  │
    │   Key   │            │   Key    │
    │(Sécurisé)           │ (Envoyé) │
    └────┬────┘            └────┬─────┘
         │                      │
         ↓                      ↓
    ┌──────────────────────────────┐
    │  POST /comptes               │
    │  - Envoyer clé publique      │
    │  - OTP reçu                  │
    │  - Aucune signature (public) │
    └──────────┬───────────────────┘
               │
               ↓
        ┌────────────────┐
        │ Backend crée   │
        │ le compte      │
        └────────┬───────┘
                 │
                 ↓
        ┌─────────────────────┐
        │ Retourne ID compte  │
        │ et statut           │
        └────────┬────────────┘
                 │
                 ↓
    ┌────────────────────────────────┐
    │  LocalStorageService.save()     │
    │  - ID du compte                 │
    │  - Numéro de téléphone          │
    │  - Clé privée (sécurisé)       │
    │  - Clé publique                 │
    └────────┬───────────────────────┘
             │
             ↓
    ┌──────────────────────┐
    │ ApiClient.configure()│
    │ Prêt pour les appels │
    │ avec signature       │
    └────────┬─────────────┘
             │
             ↓
        ┌────────────────┐
        │ Authentifiée ✓ │
        │ Prête pour API │
        └────────────────┘
```

## 🛡️ Sécurité

### Signatures ECDSA P-256

**Toutes les requêtes** (sauf 4 routes publiques) sont signées:

```
Requête HTTP:
  POST /cercles HTTP/1.1
  Content-Type: application/json
  x-mondo-membre: mem-123
  x-mondo-horodatage: 2024-11-18T10:00:00Z
  x-mondo-signature: <base64 signature>
  
  {
    "nom": "Ma tontine",
    ...
  }

Signature du JSON canonique:
  {"corps":{...},"chemin":"/cercles","horodatage":"...","methode":"POST"}
  ↓ ECDSA P-256 sign
  Signature = r||s en base64
```

### Stockage des Clés

```
┌──────────────────────────────────┐
│ Clé Privée                       │
│ ✓ Générée localement             │
│ ✓ Jamais envoyée au serveur      │
│ ✓ Stockée avec flutter_secure_   │
│   storage (encryptée par le OS)  │
│ ✓ Automatiquement restaurée      │
│   après redémarrage              │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ Clé Publique                     │
│ ✓ Envoyée au serveur lors du     │
│   signup                         │
│ ✓ Stockée localement avec        │
│   SharedPreferences              │
│ ✓ Utilisée pour vérifier la      │
│   signature côté serveur         │
└──────────────────────────────────┘
```

## 📱 Persistance de Session

```
App Startup:
  1. Vérifier hasSessionProvider
  2. Si true:
     a) Récupérer savedSessionProvider
     b) Restaurer les données de session
     c) Vérifier avec le backend (/comptes/moi)
     d) Si valide: naviguer vers /home
     e) Si invalide: naviguer vers /login
  3. Si false:
     a) Naviguer vers /login

Logout:
  1. ApiClient.reset()
  2. LocalStorageService.clearSession()
  3. Naviguer vers /login
```

## 🚀 Déploiement en Production

### Avant le Déploiement

1. ✅ Tester tous les services
2. ✅ Vérifier la gestion des erreurs
3. ✅ Tester la signature ECDSA P-256
4. ✅ Vérifier la persistance de session
5. ✅ Tester sur appareil réel
6. ✅ Adapter l'URL de l'API dans `.env`

### Configuration de l'API

```
.env (production):
API_URL=https://api.mondo.example.com

Ne pas hardcoder l'URL dans le code!
Utiliser toujours ApiConfig.baseUrl
```

### Logging

```
Production: Réduire le level de log
// Avant build:
// _logger.level = Level.warning;

// Ou utiliser une variable d'environnement:
const bool kDebugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);
```

## 📚 Fichiers de Référence

| Fichier | Rôle |
|---------|------|
| `SETUP.md` | Guide complet de setup |
| `INTEGRATION_API.md` | Documentation d'utilisation |
| `lib/config/api_config.dart` | Configuration centralisée |
| `lib/models/api_models.dart` | Modèles Freezed |
| `lib/services/api_client.dart` | Client HTTP |
| `lib/services/crypto_service.dart` | ECDSA P-256 |
| `lib/services/auth_service.dart` | Authentification |
| `lib/examples/` | Exemples de code |

## 🎯 Points Clés

1. **Riverpod**: Tous les widgets doivent être `ConsumerWidget` ou `ConsumerStatefulWidget`
2. **Providers**: Toujours accéder aux services via les providers, jamais créer directement
3. **Signatures**: Automatiques pour toutes les requêtes non-publiques
4. **Erreurs**: Toutes les erreurs lancent `ApiException` avec détails
5. **Logs**: Tous les appels sont loggés pour le debugging
6. **Persistance**: Session automatiquement sauvegardée et restaurée
7. **Code Gen**: Ne jamais éditer `.freezed.dart` et `.g.dart`

---

**L'architecture est prête pour la production!** ✨
