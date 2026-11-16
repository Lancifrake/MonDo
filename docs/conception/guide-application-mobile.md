# Guide pour l'application mobile

Pour qui construit l'application (Flutter) et veut la brancher au serveur sans se perdre. Le détail de chaque route est dans [api.md](api.md) ; ce guide dit **par où commencer, dans quel ordre, et ce qui piège**.

## L'idée en trois phrases

- Il n'y a **ni session, ni mot de passe, ni jeton**. Le téléphone crée une clé, et **chaque requête est signée** par cette clé.
- MonDo **ne touche jamais l'argent** : le membre paie par Mobile Money hors de l'application, puis le déclare, et celui qui reçoit le confirme.
- L'application n'a **rien à faire avec la blockchain**. Le serveur inscrit lui-même des empreintes sur la chaîne. L'application peut seulement afficher la preuve d'un événement avec `GET /cercles/:id/registre`.

## 1. Lancer le serveur chez soi

```bash
cd src/serveur
corepack pnpm install
corepack pnpm build
NODE_ENV=development corepack pnpm start      # http://127.0.0.1:3000
```

- Sans `DATABASE_URL`, la base est en mémoire : tout disparaît à l'arrêt, c'est voulu pour essayer.
- **Aucun SMS ne part.** Le code à 6 chiffres s'écrit dans le journal du serveur : cherche une ligne `+237… : …`.
- Adresse du serveur depuis l'application : simulateur iOS `http://127.0.0.1:3000`, émulateur Android `http://10.0.2.2:3000`, vrai téléphone `http://<adresse de ton ordinateur>:3000` sur le même Wi-Fi. Mets cette adresse **à un seul endroit** du code, pour la changer sans chercher.
- `GET /sante` répond `{"statut":"ok"}` sans signature : c'est le premier appel à essayer.

## 2. La clé de l'appareil

- Algorithme : **ECDSA, courbe P-256, hachage SHA-256**.
- La clé privée **ne quitte jamais le téléphone**. Garde-la dans le stockage sécurisé du système (Keychain sur iOS, Keystore sur Android), jamais dans un fichier ou les préférences.
- Au serveur, on envoie seulement la **clé publique, au format JWK** : `{"kty":"EC","crv":"P-256","x":"…","y":"…"}`, avec `x` et `y` en base64url.
- La **signature** est le format brut **r puis s, 64 octets, encodés en base64 standard**. Ce n'est **pas** le format DER que beaucoup de bibliothèques renvoient par défaut : c'est l'erreur la plus fréquente. Si le serveur répond 401 alors que tout semble juste, vérifie d'abord ça.

## 3. Signer une requête

Trois en-têtes sur chaque requête (sauf les routes marquées « publique » dans `api.md`) :

| En-tête | Valeur |
|---|---|
| `x-mondo-membre` | l'identifiant du compte, reçu à l'inscription |
| `x-mondo-horodatage` | la date ISO 8601, par exemple `2026-11-16T12:00:00.000Z` |
| `x-mondo-signature` | la signature du message ci-dessous |

**Le message signé** est le JSON de `{ methode, chemin, horodatage, corps }` avec ces règles :

1. **Clés triées par ordre alphabétique**, à tous les niveaux, y compris dans les objets imbriqués.
2. **Aucun espace** ni retour à la ligne.
3. `methode` en **majuscules** (`GET`, `POST`).
4. `chemin` : ce que le serveur lit, **avec la requête** s'il y en a (`/cercles/bareme?nombreMembres=5&montant=10000`), sans le domaine.
5. `corps` : l'objet envoyé, ou **`null`** quand il n'y a pas de corps ou qu'il est vide.
6. `horodatage` : **exactement la même chaîne** que celle de l'en-tête.

Deux exemples **calculés avec le vrai code du serveur** : ta fonction doit produire exactement ces textes, caractère pour caractère, avant que tu ne la branches.

```
GET /cercles, horodatage 2026-11-16T12:00:00.000Z, sans corps
{"chemin":"/cercles","corps":null,"horodatage":"2026-11-16T12:00:00.000Z","methode":"GET"}

POST /cotisations/abc/paiement, horodatage 2026-11-16T12:00:01.000Z, corps {"referenceTransaction":"OM-123"}
{"chemin":"/cotisations/abc/paiement","corps":{"referenceTransaction":"OM-123"},"horodatage":"2026-11-16T12:00:01.000Z","methode":"POST"}
```

Règles du serveur à connaître :
- Une requête **vaut 5 minutes** : l'horloge du téléphone doit être à l'heure.
- Une requête **ne vaut qu'une fois** : deux requêtes identiques sont refusées. Deux appels dans la même milliseconde doivent donc avoir des horodatages différents. Fais croître l'horodatage d'au moins 1 ms à chaque requête.
- Un champ inconnu dans un corps donne **400** (les corps sont stricts). Un compte bloqué reçoit **423**. Trop de demandes : **429**.
- Les montants sont des **entiers en FCFA**. Les identifiants sont des UUID.

## 4. S'inscrire, étape par étape

1. `POST /comptes/otp` avec `{ "numero": "+237…" }`. Le code part par SMS (en développement : dans le journal du serveur).
2. Crée la paire de clés **maintenant**.
3. Signe ce message avec la nouvelle clé, la **preuve** que tu la détiens :
   ```
   {"clePublique":{"crv":"P-256","kty":"EC","x":"…","y":"…"},"nom":"…","numero":"+237…","objet":"inscription"}
   ```
   (mêmes règles : clés triées, sans espace.)
4. `POST /comptes` avec `{ numero, nom, clePublique, preuve, codeOtp }`. La réponse contient l'`id` du compte : **garde-le**, c'est la valeur de `x-mondo-membre`.

Le serveur ne vérifie pas le code SMS dans une route à part : il est vérifié **dans le même appel** que l'inscription. L'écran du code doit donc garder la valeur saisie et l'envoyer avec les autres champs.

## 5. Les écrans actuels et les routes qui leur correspondent

Le serveur dit **cercle** là où l'écran dit **tontine** : c'est le même objet.

| Écran | Ce qu'il fait au serveur |
|---|---|
| Bienvenue | rien |
| Inscription (nom, numéro) | `POST /comptes/otp` |
| Code SMS | garder le code, puis `POST /comptes` (voir plus haut) |
| Code PIN | **pas d'équivalent exact**. Le serveur a seulement un *code secret de récupération* de 4 à 8 chiffres (`POST /comptes/moi/code-secret`), utile pour retrouver son compte depuis un nouveau téléphone. Un PIN pour déverrouiller l'application peut rester **local** (et la biométrie du téléphone), sans le serveur. À trancher avec l'équipe. |
| Accueil (mes tontines, échéances) | `GET /cercles` et `GET /cotisations` |
| Créer une tontine | voir ci-dessous |

**Créer une tontine** demande une étape de plus qu'un simple formulaire :
1. `GET /cercles/bareme?nombreMembres=…&montant=…` renvoie les **frais par place**. Cette liste va **telle quelle** dans le champ `bareme` du règlement.
2. Le règlement contient : `montant`, `frequence` (`hebdomadaire`, `mensuelle` ou `jours`, avec `periodeJours` dans ce dernier cas), `nombreMembres` (3 à 50), `penaliteRetard`, `delaiGraceJours`, `ouvert`, `datePremierTour` (date ISO), `bareme`, et en option `rappelsAvantEcheanceJours`, `scoreMinimum`, `ordreFixe` pour un cercle privé.
3. L'organisateur **signe le règlement** : le message est le JSON `{ objet: "reglement", organisateurId, reglement, placeSouhaitee }`, mêmes règles que plus haut. Quiconque rejoint signe ensuite un *engagement* qui reprend l'empreinte de ce règlement.
4. `POST /cercles` avec `{ reglement, placeSouhaitee, signature }`.

Rien dans le règlement ne se modifie après la signature : c'est ce qui le rend opposable.

## 6. Pour tester sans rien payer ni inviter personne

Hors production seulement :
- `POST /comptes/:id/niveau2` fait passer son propre compte au niveau d'identité 2, pour essayer les cercles ouverts sans déposer de pièce.
- `POST /demonstration/cercles/:cercleId/membres-fictifs`, `/suite` et `/avance` jouent un cycle entier, avec des membres fictifs, depuis **un seul téléphone** : retards, défaut, pénalité, mise en demeure.

## 7. Une implémentation qui marche, à lire

`src/serveur/src/testing/client.ts` et `telephone.ts` sont un client TypeScript qui signe **exactement** comme le serveur l'attend. Quand tu hésites sur un détail, regarde ce qu'ils font : ils sont testés à chaque modification du serveur.

## 8. Règles de l'équipe

Voir [CONTRIBUTING.md](../../CONTRIBUTING.md). Pour le mobile : une branche `feat/sujet-court`, une pull request par étape terminée, et jamais de donnée réelle dans le dépôt (numéros, noms et pièces inventés).
