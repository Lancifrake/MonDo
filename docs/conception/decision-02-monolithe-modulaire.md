# Décision 02 : un monolithe modulaire pour le serveur MonDo

Date : 03/11/2026. Statut : validée par David.

## Question
Comment découper le serveur de MonDo pour un prototype livré en moins d'un mois par une équipe de 5, sans fermer la porte à une montée en charge (cible lointaine : 1 million d'utilisateurs) ?

## Options considérées
- **Monolithe simple** : un programme au code mélangé. Rapide au début, illisible ensuite. Écarté.
- **Microservices** : un programme et une base par module, reliés par le réseau. Écarté pour le prototype et la V1 : confirmer une cotisation touche la cotisation, le score et le registre, donc plusieurs appels réseau à garder cohérents (files de messages, reprises, copies de données en retard). Ce travail n'apporte rien à 50 tontines et 1000 utilisateurs.
- **Monolithe modulaire** : un seul programme découpé en modules aux frontières claires. Retenu.

## Décision
Un seul serveur, six modules (voir `docs/conception/architecture/mondo-architecture.excalidraw`) : Comptes et identité, Cercles et règlement, Score et ordre de passage, Cotisations et confirmations, Planificateur, Dossier de preuve et mises en demeure. Le registre blockchain et les opérateurs restent des systèmes externes, derrière des connecteurs.

## Règles à respecter
1. **Propriété des données.** Chaque module ne lit et n'écrit que ses propres tables. Pour le reste, il appelle l'interface de l'autre module. C'est ce qui permet d'en extraire un plus tard.
2. **Événements internes.** Les modules se préviennent par des événements (« cotisation confirmée », « défaut constaté », « cercle complet »). Le score se calcule à partir de ces événements, sans que Cotisations ou Planificateur le connaissent.
3. **Serveur sans mémoire de session.** L'état est dans la base, pas dans le serveur : on peut lancer plusieurs copies derrière un répartiteur de charge.
4. **File d'attente pour les envois.** SMS et rappels partent en arrière-plan. Une panne de la passerelle ne bloque pas les cotisations.
5. **Tâches planifiées rejouables.** Le planificateur peut être relancé ou dupliqué sans envoyer deux fois le même rappel (identifiant unique par rappel).
6. **Registre par lots.** Les empreintes sont regroupées dans un arbre de hachage et une seule racine est inscrite par heure ou par jour. Chaque preuve individuelle reste vérifiable. Sans cela, 1 million de cotisations par semaine feraient 1 million de transactions.
7. **Fichiers hors base.** Pièces d'identité et documents signés dans un stockage d'objets chiffré.
8. **Connecteurs derrière des interfaces.** Mobile Money simulé, prestataire d'identité simulé et registre se remplacent par les vrais sans toucher au métier.

## Où cela se limite
- Estimation sur hypothèses, non mesurée : 1 million d'utilisateurs en cercles de 10 membres, cotisation hebdomadaire, donne environ 1 à 2 cotisations par seconde en moyenne, 100 à 200 écritures par seconde en pointe. Une base classique avec une réplique en lecture suffit. Ce qui pèse avant le serveur : le coût et les limites des SMS, le registre, la vérification d'identité, le cadre réglementaire.
- Premier candidat à l'extraction si on le mesure nécessaire : le **planificateur et l'envoi de messages**, parce qu'il travaille par vagues (dates limites) et peut tomber sans arrêter les cotisations. Signes à surveiller : les rappels ralentissent les écrans, une panne SMS a gêné des cotisations, deux équipes se marchent dessus. Avant cela, la file d'attente (règle 4) règle l'essentiel.

## Conséquences
- Le dossier de preuve lit toutes les données dans une seule base : plus simple et plus sûr pour une pièce destinée à un litige.
- Aucune technologie n'est choisie (langage, hébergeur, base). C'est l'étape suivante.
- Le schéma de zoom du serveur (liens entre modules, événements, écritures dans le registre) reste à faire.
