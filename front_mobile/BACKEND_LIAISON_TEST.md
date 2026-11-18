# Test de Liaison Backend - TIER 1 Screens

Documento  de test pour vérifier que tous les écrans TIER 1 se connectent correctement au backend NestJS.

## Écrans Créés

### 1. LoginScreen
**Fichier**: `lib/screens/login/login_screen.dart`

**Endpoint Utilisé**: 
- `GET /comptes/moi` (avec signature ECDSA P-256)

**Flux**:
1. Utilisateur entre son PIN (6 chiffres)
2. Appel API: `GET /comptes/moi` avec header `x-mondo-signature`
3. Si succès: Profil chargé, navigation vers écran principal
4. Si erreur 401: PIN incorrect
5. Si erreur 403: Clé privée invalide
6. Si erreur 500: Erreur serveur

**Dépendances**:
- `authStateProvider` (Riverpod)
- `CryptoService` pour signature ECDSA P-256
- `ApiClient` pour requête HTTP

**Notes**:
- La signature est ajoutée automatiquement par `ApiClient` pour routes non publiques
- Le PIN est stocké localement (pas envoyé au serveur)
- La session est sauvegardée localement via `LocalStorageService`

---

### 2. CotisationsListScreen
**Fichier**: `lib/screens/cotisations/cotisations_list_screen.dart`

**Endpoints Utilisés**:
- `GET /cercles` (récupérer cercles utilisateur)
- `GET /cotisations?statut=...` (cotisations filtrées)

**Flux**:
1. Écran charge les cercles de l'utilisateur
2. Utilisateur sélectionne un cercle
3. Écran affiche les cotisations du cercle filtrées par statut (due/declaree/confirmee)
4. Utilisateur clique "Payer Maintenant" → navigation vers PaymentDeclareScreen

**Dépendances**:
- `mesCerclesRefreshableProvider` (Riverpod)
- `mesCotisationsFiltreesProvider(statut)` (Riverpod)
- `CotisationsService` pour appels API
- `CerclesService` pour appels API

**Notes**:
- La liste peut être rafraîchie via RefreshIndicator
- Filtres par cercle et statut implémentés
- Cards affichent: bénéficiaire, montant, date limite, statut

---

### 3. PaymentDeclareScreen
**Fichier**: `lib/screens/cotisations/payment_declare_screen.dart`

**Endpoint Utilisé**:
- `POST /cotisations/:id/paiement`

**Flux**:
1. Affiche résumé de la cotisation (montant, bénéficiaire, date limite)
2. Utilisateur sélectionne opérateur (Orange Money, MTN Money, etc.)
3. Utilisateur entre référence de transaction (ex: 13 chiffres Mobile Money)
4. Appel API: `POST /cotisations/:id/paiement` avec payload:
   ```json
   {
     "methode": "orange_money",
     "referenceTransaction": "123456789",
     "signature": "mock_signature"
   }
   ```
5. Si succès: Navigation vers PaymentConfirmationScreen
6. Si erreur: Affichage message d'erreur

**Dépendances**:
- `cotisationsServiceProvider` (Riverpod)
- `CotisationsService.declarerPaiement()`

**Notes**:
- Étape 1 de 2 du flux de paiement
- Signature actuellement mock (`mock_signature`)
- TODO: Implémenter vraie signature ECDSA P-256

---

### 4. PaymentConfirmationScreen
**Fichier**: `lib/screens/cotisations/payment_confirmation_screen.dart`

**Endpoint Utilisé**:
- `POST /cotisations/:id/confirmation`

**Flux**:
1. Affiche résumé du paiement déclaré
2. Utilisateur prend photo OU sélectionne image de galerie comme preuve
3. Image convertie en base64
4. Appel API: `POST /cotisations/:id/confirmation` avec payload:
   ```json
   {
     "preuve": "<base64_encoded_image>",
     "signature": "mock_signature"
   }
   ```
5. Si succès: Message de confirmation, retour à liste cotisations
6. Si erreur: Affichage message d'erreur

**Dépendances**:
- `cotisationsServiceProvider` (Riverpod)
- `CotisationsService.confirmerPaiement()`
- `image_picker` package pour capture photo/galerie

**Notes**:
- Étape 2 de 2 du flux de paiement
- Image convertie en base64 pour transmission
- Signature actuellement mock (`mock_signature`)
- TODO: Implémenter vraie signature ECDSA P-256

---

### 5. NotificationsScreen
**Fichier**: `lib/screens/notifications/notifications_screen.dart`

**Endpoints Utilisés**:
- `GET /notifications` (récupérer notifications)
- `POST /notifications/:id/lue` (marquer comme lue)

**Flux**:
1. Écran charge les notifications
2. Utilisateur peut filtrer (toutes/non-lues/lues)
3. Utilisateur clique sur une notification → `POST /notifications/:id/lue`
4. Notification marquée comme lue, liste rafraîchie
5. Utilisateur peut supprimer une notification (menu contextuel)

**Dépendances**:
- `meNotificationsRefreshableProvider` (Riverpod)
- `NotificationsService` pour appels API

**Notes**:
- Affiche titre, message, type (cotisation/cercle/litige/score/system)
- Chaque notification affiche date relative (ex: "il y a 2h")
- Icônes et couleurs par type de notification
- Rafraîchir manuel + RefreshIndicator

---

## Corrections Apportées

### 1. Modèles API (`api_models.dart`)
- ✅ Mis à jour `Notification` avec champs: `titre`, `message`, `type`, `dateCreation`
- ✅ Ajout getter `lue` sur `Notification`
- ✅ Ajout getter `beneficiaire` sur `Cotisation` pour compatibilité

### 2. Services
- ✅ `CotisationsService.confirmerPaiement()`: Accepte `proofImagePath` et le convertit en base64
- ✅ `NotificationsService.marquerCommeLue()`: Renommé de `marquerCommeEue()`
- ✅ Ajout imports manquants: `dart:io`, `dart:convert`

### 3. Providers
- ✅ `meNotificationsRefreshableProvider`: Alias pour les notifications de l'utilisateur
- ✅ Déjà existant: `mesCerclesRefreshableProvider`, `mesCotisationsFiltreesProvider`

### 4. Utilities (`format.dart`)
- ✅ Ajout `formatDate()`: Formate date ISO 8601 → "15 nov 2026"
- ✅ Ajout `formatDateTimeRelative()`: Formate date relative → "il y a 2h"
- ✅ Import `intl` package pour localisation FR

---

## Checklist de Test Backend

### Test Login
- [ ] Serveur accepte requête `GET /comptes/moi` avec signature valide
- [ ] Retourne profil utilisateur avec `id`, `numero`, `nom`, `niveau`
- [ ] Rejette requête avec signature invalide (HTTP 403)
- [ ] Rejette requête sans PIN valide (HTTP 401)

### Test Cotisations - Déclaration
- [ ] Serveur accepte `POST /cotisations/:id/paiement`
- [ ] Valide champs: `methode`, `referenceTransaction`
- [ ] Retourne cotisation avec statut `declaree`
- [ ] Enregistre `declareeLe` avec timestamp

### Test Cotisations - Confirmation
- [ ] Serveur accepte `POST /cotisations/:id/confirmation`
- [ ] Décote image base64 correctement
- [ ] Retourne cotisation avec statut `confirmee`
- [ ] Enregistre `confirmeeLe` avec timestamp

### Test Notifications
- [ ] Serveur retourne `GET /notifications` avec liste `Notification[]`
- [ ] Chaque notification a: `id`, `titre`, `message`, `type`, `dateCreation`, `lue_le` (nullable)
- [ ] Serveur accepte `POST /notifications/:id/lue`
- [ ] Met à jour `lue_le` avec timestamp
- [ ] Notifications non lues retournent `lue_le: null`

---

## Configuration Requise

**Pubspec.yaml - Dépendances**:
- ✅ `flutter_riverpod: ^2.0.0`
- ✅ `dio: ^5.0.0`
- ✅ `freezed_annotation: ^2.0.0`
- ✅ `json_serializable: ^6.0.0`
- ✅ `image_picker: ^1.0.0` (pour PaymentConfirmationScreen)
- ✅ `intl: ^0.19.0` (pour formatDate/formatDateTimeRelative)
- ✅ `cryptography: ^2.0.0`
- ✅ `logger: ^2.0.0`

---

## Prochaines Étapes

1. **Compiler les écrans**
   ```
   flutter pub get
   flutter analyze
   ```

2. **Tester liaisons backend**
   - Lancer backend NestJS en local
   - Exécuter chaque écran et vérifier appels API
   - Vérifier signatures ECDSA P-256

3. **Implémenter vraie signature**
   - Remplacer `mock_signature` par vraie signature
   - Utiliser `CryptoService` pour signer

4. **Créer git commits**
   - 1 commit par écran
   - Messages en français: "feat: add LoginScreen", etc.

5. **Passer à TIER 2**
   - 7 écrans restants: Cercles, Adhésion, Litiges, Score
