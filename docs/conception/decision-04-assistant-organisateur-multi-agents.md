# Décision 04 : un assistant de l'organisateur, en agents, en mode autonome ou manuel

Date : 03/11/2026. Statut : **proposée**, choix de l'option par David, détails à valider avec l'équipe et à confirmer avec l'enseignant.

## Question
La grille d'évaluation du projet (Smart Realization X5) demande un système multi-agents mesuré (cycles, messages, indéterminisme, mémoire) et deux modes d'usage : autonome et manuel. Comment l'intégrer à MonDo sans toucher à ses principes ?

## Options considérées
1. Simulation multi-agents du cercle (agents membres aux profils variés), utile aussi pour régler le score.
2. **Assistant de l'organisateur** en mode autonome ou manuel. **Retenu par David.**
3. Agents qui négocient les échanges de place. Écarté : trop long et trop imprévisible pour un produit qui doit être sûr.

## Décision
Un assistant aide l'organisateur d'un cercle à suivre les cotisations, relancer et préparer les suites d'un retard. Il est composé de quelques agents qui coopèrent par messages :

| Agent | Rôle |
|---|---|
| Surveillance | lit les événements du cercle (« cotisation confirmée », « date limite dépassée », « défaut constaté ») et repère les situations à traiter |
| Relance | choisit quoi envoyer, à qui et quand, dans les limites du règlement |
| Preuve | prépare la mise en demeure et le dossier de preuve quand un défaut est constaté |
| Coordinateur | reçoit les propositions des autres agents et applique le mode choisi |

**Deux modes, choisis par l'organisateur pour son cercle :**
- **Autonome** : le coordinateur exécute lui-même les actions prévues (rappels, mise en demeure datée).
- **Manuel** : le coordinateur propose l'action (« relancer Paul ? ») et l'organisateur accepte ou refuse. Ce qui est refusé n'est pas envoyé.

## Limites non négociables
1. **Un agent n'agit que dans ce que le règlement signé a déjà fixé** : rappels, délais, pénalités et mise en demeure prévus. Il n'invente rien.
2. **Un agent ne touche jamais à l'argent** (MonDo ne détient pas les fonds), ne confirme jamais un paiement et ne modifie jamais un score ni l'ordre de passage. Le score reste la somme des événements et l'ordre reste déterministe.
3. **Toute action automatique est tracée** : événement enregistré, visible par les membres concernés, donc contestable.
4. **Un litige reste traité par l'Administrateur**, pas par un agent.

## Place dans l'architecture
- L'assistant ne remplace pas le **Planificateur** (module 5 de la décision 02), qui reste le moteur des dates limites et des tâches rejouables. L'assistant ajoute une couche de décision (que faire, pour qui, quand) au-dessus des événements qu'il publie.
- Les agents consomment les événements internes et envoient leurs demandes d'envoi dans la file d'attente existante. Aucun nouveau service externe.
- Le choix du mode (autonome ou manuel) est un paramètre du cercle.

## Mesures pour la grille d'évaluation
- **Cycles** : temps pour traiter un tour complet (cible : moins de 2 secondes).
- **Charge de communication** : nombre de messages échangés entre agents pour traiter un retard.
- **Indéterminisme** : relancer 100 fois le même scénario (10 membres, un défaut) et vérifier que les actions proposées sont identiques.
- **Mémoire** : état de chaque agent borné, pas de fuite sur plusieurs cycles.

## Mise en œuvre (03/11/2026)
Branché sur les événements internes du serveur (`src/serveur/src/modules/assistant`) :
- le Planificateur examine les cotisations dues et publie « échéance proche » et « échéance dépassée », une fois par jour et par cotisation ; le constat de défaut publie « défaut constaté » ;
- pour chaque événement, les agents tournent avec les limites lues dans le règlement signé du cercle, et chaque action est enregistrée dans un journal (`executee`, `en_attente`, `acceptee`, `refusee`, `hors_reglement`) ;
- la mise en demeure est **préparée** par le module Preuve et **envoyée** par l'assistant : tout de suite en mode autonome, après accord de l'organisateur en mode manuel ;
- envois simulés : la file d'envoi SMS n'existe pas encore.

Choix faits faute de règle écrite, à valider :
1. **Mode par défaut : manuel** tant que l'organisateur n'a pas choisi (aucune action sans accord).
2. **Jours de rappel avant échéance : champ facultatif du règlement signé** (`rappelsAvantEcheanceJours`), vide par défaut : sans ce champ, aucun rappel avant la date limite.
3. **Mise en demeure toujours autorisée** pour les agents : le flow 7 la fait suivre tout défaut constaté.

## Points ouverts
- Confirmer avec l'enseignant que ce système satisfait la grille multi-agents.
- Dans quelle mesure l'organisateur peut changer de mode en cours de cycle.
- Un seul organisateur par cercle : que se passe-t-il s'il est absent ? (reprise par un autre membre, ou par l'Administrateur)
- Technologie des agents : simples classes TypeScript qui s'échangent des messages, avant d'envisager un modèle de langage. Un modèle de langage ne doit pas décider d'une action sur l'argent ou le score.

## À aligner
Schéma d'architecture (bloc « Assistant »), cas d'utilisation (extension du cas « Relancer »), flows 6 et 7 (modes autonome et manuel), README.
