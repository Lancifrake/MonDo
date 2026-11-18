# ⚡ Quick Start - 5 Minutes

Démarrage ultra-rapide de l'application MonDo.

## 🚀 Étapes

### 1. Installer les dépendances (1 min)

```bash
flutter pub get
```

### 2. Générer le code (2 min)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurer l'API (30 sec)

Éditer `.env`:
```
API_URL=http://localhost:3000
```

Ou laisser la valeur par défaut si le backend est sur `localhost:3000`.

### 4. Lancer l'app (30 sec)

```bash
flutter run
```

✅ **Done!** L'app est lancée et connectée au backend.

---

## 📱 Tester l'Application

### Flux d'Authentification

1. Cliquer sur "S'inscrire"
2. Entrer un numéro: `237123456789`
3. Attendre le code OTP (en dev, visible dans les logs)
4. Entrer le code
5. Entrer le nom: `Jean Dupont`
6. Valider l'inscription

✅ Connexion réussie!

### Accéder aux Cercles

1. Voir la liste des cercles dans l'écran d'accueil
2. Cliquer sur un cercle pour voir les détails
3. Rejoindre un cercle depuis le catalogue

### Déclarer un Paiement

1. Aller dans "Cotisations"
2. Cliquer sur une cotisation due
3. Entrer la référence de paiement
4. Confirmer

✅ Paiement déclaré!

---

## 🛠️ Mode Watch (Recommandé)

Pour un développement fluide, utiliser le mode watch pour la génération de code:

```bash
flutter pub run build_runner watch
```

Cela regénère automatiquement le code quand vous modifiez les fichiers `.dart`.

---

## 📚 Prochaines Étapes

### Pour Comprendre l'Architecture
→ Lire **ARCHITECTURE_OVERVIEW.md**

### Pour Intégrer les Écrans
→ Lire **INTEGRATION_API.md** + regarder les exemples dans `lib/examples/`

### Pour le Setup Complet
→ Lire **SETUP.md**

### Pour Déployer
→ Vérifier **CHECKLIST_DEPLOYMENT.md**

---

## 🐛 Dépannage Rapide

### "Build Runner error"
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Connection refused"
Vérifier que le backend tourne sur `http://localhost:3000`

### "Erreur de signature"
La signature ECDSA P-256 est injectée automatiquement. Si erreur:
- Vérifier que l'authentification a réussi
- Vérifier les logs pour plus de détails

### "Session non restaurée"
C'est normal à la première utilisation. Après la première authentification, la session sera restaurée.

---

## ✅ Points Clés

1. ✅ **Zéro configuration** - Tout est pré-configuré
2. ✅ **Code generation** - `build_runner` doit être exécuté une fois
3. ✅ **Signatures automatiques** - Toutes les requêtes sont signées
4. ✅ **Session persistante** - Sauvegardée et restaurée automatiquement
5. ✅ **Logging complet** - Tous les appels sont loggés

---

## 📞 Besoin d'Aide?

- Logs complets: `flutter run` affiche tout
- Documentation: `README.md`, `SETUP.md`, `INTEGRATION_API.md`
- Exemples: `lib/examples/`

---

**C'est tout!** Vous êtes maintenant prêt à développer. 🎉
