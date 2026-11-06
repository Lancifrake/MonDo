# Audit de sécurité du prototype, 06/11/2026

Relecture du serveur (`src/serveur`), du contrat (`src/contrat`) et de l'intégration continue, à l'état de `main` après la PR 18. Audit interne fait par Claude Code : il ne remplace ni un audit indépendant du contrat ni un test d'intrusion, obligatoires avant tout pilote réel (SECURITY.md).

## Résumé
- 2 failles réelles trouvées dans le code, corrigées : rejeu de requête signée (élevée), absence de plafond sur les codes SMS (moyenne).
- 2 trous corrigés juste avant, dans la PR 18 : lots du registre jamais inscrits sur la chaîne, niveau 2 d'identité auto-déclaré même en production.
- 2 durcissements mineurs, corrigés : jeton de la CI en lecture seule, en-tête `x-powered-by` retiré.
- 3 points de règle métier, tranchés par David le 06/11 et codés (PR suivante).
- Rien de grave relevé dans le contrat, les requêtes SQL ou les contrôles d'accès.

## Failles corrigées

### 1. Rejeu d'une requête signée (élevée), corrigée
L'anti-rejeu retenait le texte base64 de la signature. Or une même signature s'écrit de plusieurs façons valides : padding retiré ou ajouté, espace en tête, et surtout malléabilité ECDSA (s remplacé par n − s donne une seconde signature valide du même message). Quelqu'un qui interceptait une requête pouvait la rejouer pendant 5 minutes, par exemple une déclaration de paiement ou une adhésion.
Correction : l'anti-rejeu retient l'empreinte SHA-256 du membre et du message signé (méthode, chemin, horodatage, corps). Migration `015_requetes_vues`. Tests : trois variantes d'encodage et la signature malléable sont refusées.

### 2. Codes SMS sans plafond (moyenne), corrigée
Un code par minute et par numéro, sans autre limite : 1 440 SMS par jour vers un même numéro (harcèlement, coût) et un code neuf chaque minute pour deviner. Le contrôle « une minute » était aussi lu puis écrit en deux temps : deux demandes simultanées passaient toutes les deux.
Correction : au plus 5 codes par numéro sur 24 h glissantes, contrôles et écriture en une seule instruction SQL. Migration `016_plafond_otp`. Tests : sixième code refusé jusqu'au lendemain, trois demandes simultanées donnent un seul SMS.
Reste à faire chez l'hébergeur : une limite par adresse IP (un attaquant peut encore viser des milliers de numéros différents). Elle dépend du mandataire inverse (adresse réelle du client), donc de l'hébergement, pas encore choisi.

### 3. Lots du registre jamais inscrits (PR 18), corrigée
`fermerLot` n'était appelé que par les tests : rien ne partait sur la chaîne. Le planificateur ferme et inscrit désormais un lot à chaque passage, et réinscrit les lots en échec.

### 4. Niveau 2 d'identité auto-déclaré (PR 18), corrigée
`POST /comptes/:id/niveau2` donnait le niveau 2 sans aucune pièce, y compris en production. Refusé en production tant qu'aucun prestataire de vérification n'est branché.

### 5. Durcissements mineurs, corrigés
- Intégration continue : `permissions: contents: read`, le jeton ne peut plus écrire dans le dépôt.
- Serveur : l'en-tête `X-Powered-By: Express` n'est plus envoyé (vérifié par l'essai de démarrage).

## Points vérifiés sans constat
- **Authentification** : toute route exige une requête signée sauf `/sante`, `POST /comptes/otp` et `POST /comptes` ; identité lue dans la signature, jamais dans le corps ; horodatage à plus ou moins 5 minutes ; chemin et paramètres inclus dans le message signé.
- **Inscription** : preuve de détention de la clé, code SMS vérifié avant de dire si le numéro existe, code stocké haché et salé, comparaison à temps constant, essai compté avant la comparaison.
- **Contrôles d'accès** : déclarer (payeur seul), confirmer (bénéficiaire seul), litige (parties et administrateur, jamais un administrateur partie), assistant (organisateur seul), dossier de preuve (autres membres du cercle, après un défaut), niveau 2 (soi-même).
- **Concurrence** : dernière place d'un cercle (verrou de ligne), confirmations et décisions (mises à jour conditionnelles), constats rejouables (tâches traitées), file SMS (`FOR UPDATE SKIP LOCKED`).
- **Injection SQL** : toutes les requêtes sont paramétrées, aucune concaténation de valeur.
- **Validation** : chaque corps passe par un schéma Zod strict (champs inconnus refusés, bornes sur les montants et les textes).
- **Fuites** : erreurs 500 sans détail technique, `/sante` sans détail, numéro absent des journaux de la file SMS, SMS et registre simulés interdits en production.
- **Contrat** : rôles OpenZeppelin, une seule inscription par racine, refus de tout envoi d'argent, arrêt d'urgence, vérification d'inclusion identique au serveur (test croisé), Slither sans constat.
- **Secrets** : aucun dans le dépôt ni dans l'historique relu, `.env`, `.pem` et `.key` ignorés, clés lues dans l'environnement seulement.
- **Dépendances de production** : `pnpm audit --prod` sans vulnérabilité connue (serveur et contrat).

## Règles métier tranchées par David (06/11), codées
1. **Déclaration gelée pendant un litige ouvert.** Le payeur ne change plus sa référence tant que l'administrateur n'a pas tranché ; il tranche sur la pièce d'origine. Le bénéficiaire peut toujours confirmer, ce qui clôt le litige. Colonne `en_litige` (migration 017), posée à l'ouverture, levée à la décision ou à la confirmation.
2. **Défaut dès le refus.** Après un « paiement refusé », si la fin de grâce est passée, le défaut est constaté tout de suite, avec la même tâche que le planificateur (jamais deux défauts pour un tour). Avant la fin de grâce, le payeur peut encore payer et redéclarer.
3. **Visibilité.** Cercle : avec le lien, un non-membre voit le règlement, son empreinte, le statut et les places restantes ; la liste des membres et l'ordre de passage sont réservés aux membres. Score : visible par le membre lui-même et par les membres d'un cercle commun (copie des adhésions dans le module Score, migration 018).

## Hors code, avant un pilote réel
- Audit indépendant du contrat, test d'intrusion du serveur.
- GitHub : protection de `main`, Dependabot, CodeQL, alertes de secrets, signalement privé (SECURITY.md).
- Hébergement : HTTPS obligatoire, limite par adresse IP sur `POST /comptes/otp` et `POST /comptes`, base chiffrée au repos, sauvegardes.
- Clé du compte inscripteur du registre : portefeuille dédié, peu d'ETH, rôle retirable par l'administrateur.
- Vrai prestataire de vérification d'identité et stockage chiffré des pièces (SECURITY.md, règle 7).
- Dépendances de développement : deux alertes (minimatch par ESLint, zod par Hardhat), sans effet sur le serveur en production ; à suivre lors des mises à jour.
