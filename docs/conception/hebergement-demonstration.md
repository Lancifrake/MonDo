# Héberger l'instance de démonstration

Pour une démonstration avec des **données fictives uniquement** : serveur sur Render (offre gratuite), base PostgreSQL chez Neon (offre gratuite). Le choix est motivé dans [comparatif-hebergeur-et-sms.md](comparatif-hebergeur-et-sms.md). Ce n'est **pas** une production : voir « Ce que cette instance n'est pas ».

## Ce que fait la configuration
- `render.yaml` (à la racine) construit l'image `src/serveur/Dockerfile` et la lance.
- `NODE_ENV=development` est imposé : le Dockerfile met `production`, qui refuse de démarrer sans vrai fournisseur SMS, registre réel et stockage durable. En développement, le SMS et le registre sont simulés.
- Le serveur crée ou met à jour son schéma tout seul au démarrage (`migrer`).
- Contrôle de santé : `GET /sante`.
- `autoDeploy: true` : chaque fusion dans `main` redéploie le serveur, qui redémarre (il s'endort puis se réveille).

## Étapes (faites par une personne de l'équipe)
1. **Neon** : créer un compte, un projet, puis copier la chaîne de connexion. Elle se termine par `?sslmode=require`.
2. **Render** : créer un compte, relier le dépôt GitHub, choisir « New Blueprint » et le fichier `render.yaml`.
3. Renseigner les deux variables demandées :
   - `DATABASE_URL` : la chaîne Neon.
   - `MONDO_ADMINISTRATEURS` : les identifiants des comptes administrateurs, séparés comme dans `docs/conception/api.md`. On ne les connaît qu'après la première inscription : laisser vide, s'inscrire, puis les ajouter et redéployer.
4. Ouvrir `https://<nom>.onrender.com/sante` : la réponse doit être `{"statut":"ok"}`.
5. Le code SMS d'inscription est écrit dans les **journaux** du service Render (ligne `+237… : …`).

## Ce que cette instance n'est pas
- **Le serveur s'endort** après environ 15 minutes sans requête, et le premier appel suivant prend une bonne minute. Ouvrir `/sante` avant une démonstration. Le planificateur horaire prend du retard pendant le sommeil (rattrapé au réveil).
- **Pas de disque durable** : les pièces d'identité déposées disparaissent à chaque redémarrage.
- **Routes de démonstration ouvertes** (`niveau2`, membres fictifs) : quiconque connaît l'adresse peut les appeler. Aucune donnée réelle, aucun vrai numéro.
- **Aucun SMS ni inscription sur la chaîne** : tout est simulé.
- **Pas conforme pour de vrais membres** : un hébergement hors du Cameroun est un transfert au sens de l'article 32 de la loi 2024/017. Le pilote demande un autre choix, voir le comparatif.

## Branchements à prévoir
- **Application mobile** : l'adresse du serveur devient `https://<nom>.onrender.com` (un seul endroit dans le code).
- **Console d'administration** : le serveur n'active pas CORS. La console doit donc passer par un proxy de même origine, comme `/api` en développement. Un hébergement statique avec une règle de réécriture `/api/*` vers le serveur suffit (à vérifier chez l'hébergeur retenu pour la console).
