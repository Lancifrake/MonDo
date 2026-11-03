# Politique de sécurité

MonDo manipule des données sensibles (identité, numéros de téléphone, engagements financiers) et des clés de signature. Même au stade du prototype, on travaille comme si le projet était réel.

## Signaler une vulnérabilité
**Ne pas ouvrir d'issue publique** pour un problème de sécurité.

Utiliser le signalement privé de GitHub : onglet **Security**, puis **Report a vulnerability**. Indiquer ce qui est touché, comment le reproduire et l'effet possible. Nous accusons réception sous 7 jours et tenons le signalant informé jusqu'à la correction.

Pour que ce canal fonctionne, un administrateur du dépôt doit activer « Private vulnerability reporting » dans Settings > Code security.

## Statut du projet
MonDo est en conception, sans code en production. Aucune version n'est « supportée » : seule la branche `main` est à jour. Le projet n'est pas encore utilisé avec de vrais fonds ni de vraies personnes.

## Règles pour toute l'équipe
1. **Aucun secret dans le dépôt** : mots de passe, clés d'API, clés privées, jetons, fichiers `.env`. Un exemple de configuration se nomme `.env.example` et ne contient que des valeurs factices.
2. **Aucune donnée réelle** : ni pièce d'identité, ni numéro de téléphone réel, ni photo, ni capture contenant des données personnelles. Données de test fictives uniquement.
3. **Un secret publié par erreur est compromis**, même supprimé ensuite (l'historique le garde). On le révoque et on le remplace tout de suite, puis on prévient l'équipe.
4. **La clé de signature d'un membre ne quitte jamais son téléphone.** Le serveur ne la connaît pas et n'en garde aucune copie.
5. **MonDo ne détient jamais les fonds.** Aucune fonctionnalité ne doit placer de l'argent sous le contrôle de MonDo.
6. **Le registre blockchain ne reçoit que des empreintes**, jamais de donnée personnelle, même chiffrée.
7. **Pièces d'identité** : stockage chiffré séparé de la base, accès limité et journalisé, durée de conservation définie. Jamais dans les journaux ni dans les messages d'erreur.
8. **Dépendances** : peu nombreuses, à jour, choisies avec soin. Toute dépendance nouvelle est justifiée dans la pull request.
9. **Contrats Solidity** : bibliothèques éprouvées (OpenZeppelin), tests, relecture à deux. **Aucun contrat n'est déployé avec de vrais fonds ou sur un réseau réel sans audit.** Les clés de déploiement ne sont jamais dans le code.
10. **Décisions de l'Administrateur** : il ne déplace jamais d'argent et ne modifie jamais un score à la main ; ses décisions sont inscrites au registre.

## À mettre en place avec le code
Activation de l'analyse des dépendances et des alertes de secrets de GitHub, protection de la branche `main`, vérification automatique à chaque pull request.

## Limite
Ce document est une politique d'équipe, pas un avis juridique ni un audit. Avant tout pilote réel, une revue de sécurité et un avis juridique sont nécessaires.
