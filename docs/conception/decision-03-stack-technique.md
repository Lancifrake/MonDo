# Décision 03 : choix des technologies

Date : 03/11/2026. Statut : **partiellement validée**. Validés par David : TypeScript, hébergement gratuit ou crédits étudiants, application mobile native (Expo). Le reste est une proposition, expliquée à David le 03/11, en attente de son accord point par point.

## Question
Avec quelles technologies construire, en moins d'un mois à cinq, un prototype qui suit l'architecture de `docs/conception/architecture/` et la décision 02 ?

## Changement par rapport au document de vision
Le document de vision retient une PWA installable, sans magasin d'applications. David a demandé le 03/11 une vraie application mobile : une PWA est difficile à trouver (aucune fiche dans un magasin), moins rassurante pour une application qui touche à des engagements financiers, et garde la clé de signature dans le stockage du navigateur, moins protégé. **Le client mobile devient une application native en React Native avec Expo.** Le doc de vision (« PWA installable ») et le schéma d'architecture (« PWA », « cache hors connexion ») sont à aligner.

## Choix
| Couche | Choix | Raison |
|---|---|---|
| Langage | TypeScript partout | une seule langue pour l'application, le serveur et l'administration, types partagés (validé) |
| Application mobile | React Native avec Expo (EAS Build) | une base pour Android et iOS, présence dans les magasins, clé dans le coffre du téléphone |
| Administration web | React avec Vite | page web simple pour l'Administrateur, pas de rendu serveur utile derrière une connexion |
| Serveur | NestJS (modules = les six modules de la décision 02) | la structure en modules de NestJS correspond au monolithe modulaire |
| Base de données | PostgreSQL, un schéma par module | transactions (confirmer une cotisation écrit à plusieurs endroits d'un coup), cohérence, règle 1 de la décision 02 |
| File d'attente et planificateur | pg-boss (file dans PostgreSQL) | pas de service en plus, tâches rejouables |
| Fichiers | stockage d'objets chiffré (compatible S3) | règle 7 de la décision 02 |
| SMS et Mobile Money | simulés derrière des interfaces | règle 8 de la décision 02 ; le fournisseur SMS réel reste ouvert |
| Contrat du registre | Solidity, briques OpenZeppelin, tests et déploiement avec Hardhat | Hardhat s'écrit en TypeScript, comme le reste ; Foundry écarté ; Solana écarté (Rust, peu de briques auditées, l'avantage mobile ne sert pas puisque les membres n'ont pas de portefeuille) |
| Réseau du registre | **Base Sepolia** (réseau de test) pour le prototype (validé) | frais très bas, bons outils, démarrage simple ; le contrat se redéploie tel quel sur tout réseau EVM |
| Tests | Vitest (serveur), Jest et Expo pour l'application, Maestro ou Detox pour les parcours | à fixer à l'usage |
| Organisation du code | monorepo pnpm : `mobile`, `admin`, `serveur`, `contrat`, `commun` (types partagés) | |

## Conséquences de l'application native
- **Clé de signature.** Elle doit être créée dans le coffre du téléphone (Android Keystore, iOS Secure Enclave), non exportable, déverrouillée par le code secret ou la biométrie. Les modules simples d'Expo (`expo-secure-store`) stockent un secret chiffré mais ne créent pas de clé matérielle qui signe : il faut une bibliothèque qui signe dans le coffre (par exemple `react-native-biometrics`) ou un petit module natif. **Essai technique à faire en premier** : créer la clé, signer un message en ECDSA P-256, vérifier la signature côté serveur.
- **Hors connexion.** Consultation seule (cercle, ordre, score, historique) depuis une copie locale (SQLite). Tout le reste exige le réseau. Workbox disparaît.
- **Distribution.** Prototype : build de test (APK installable directement sur Android, TestFlight sur iPhone). Au pilote : Play Store et App Store. Les comptes développeur sont payants (ordre de grandeur 25 USD une fois pour Google, 99 USD par an pour Apple, à confirmer) ; la validation d'Apple prend du temps. **Pour la démo du prototype, viser Android d'abord.**
- **Lien d'invitation.** Un lien envoyé dans un groupe WhatsApp doit ouvrir l'application si elle est installée, sinon la page du magasin (liens universels et App Links). À prévoir dans le flow 4.
- **Deux livrables au lieu d'un** : l'application et la page d'administration, avec le serveur en commun.

## Points ouverts
- Protection de la clé par le code secret : essai technique (voir plus haut).
- Fournisseur SMS réel au Cameroun, et réponse du contact de confiance par lien web plutôt que par SMS (Twilio indique le SMS bidirectionnel non supporté pour +237, à confirmer).
- Réseau du pilote : comparer Base, Arbitrum et Polygon sur le coût réel de nos lots, la disponibilité des fournisseurs de nœuds depuis le Cameroun et l'argument de confiance (Base a un séquenceur unique opéré par Coinbase ; Polygon PoS a sa propre sécurité, finalité et feuille de route à revérifier). Frais et état des réseaux non vérifiés à jour.
- Registre : contrat Solidity ou simple horodatage des racines (OpenTimestamps, horodatage RFC 3161) ? Le contrat apporte les règles lisibles sur la chaîne, l'horodatage suffit pour la preuve d'intégrité. À trancher.
- Base de données : PostgreSQL hébergé chez Supabase (base et stockage seulement, NestJS reste le serveur, ni Auth ni RLS ni fonctions Supabase) ou autre hébergeur. Limites de l'offre gratuite (pause après inactivité) à revérifier.
- Hébergement exact (gratuit ou crédits étudiants) à choisir une fois le serveur prêt.
- Notifications : push (Expo) en plus des SMS pour les rappels, à décider.

## À aligner
Doc de vision (PWA, « base Rota »), schéma d'architecture (bloc PWA, cache hors connexion), flow 4 (lien d'invitation), CLAUDE.md.
