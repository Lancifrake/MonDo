class TontineModel {
  const TontineModel({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const tontineModels = <TontineModel>[
  TontineModel(
    id: 'quartier',
    title: 'Tontine de quartier',
    description: 'Entre voisins, une réunion par mois.',
  ),
  TontineModel(
    id: 'ressortissants',
    title: 'Association de ressortissants',
    description: "Un bureau complet et une caisse d'entraide.",
  ),
  TontineModel(
    id: 'eglise',
    title: "Groupe d'église",
    description: "Cotisation chaque semaine avec une part d'entraide.",
  ),
  TontineModel(
    id: 'commercants',
    title: 'Tontine de commerçants',
    description: 'Cycles courts, montants plus élevés, argent bien contrôlé.',
  ),
  TontineModel(
    id: 'scolarite',
    title: 'Caisse pour la scolarité',
    description: "On met de côté pour la rentrée.",
  ),
  TontineModel(
    id: 'zero',
    title: 'Partir de zéro',
    description: 'Tu règles tout toi-même.',
  ),
];

const predefinedRoles = [
  'Président',
  'Trésorier',
  'Secrétaire',
  'Censeur',
  'Commissaire aux comptes',
];

/// Tout ce que l'utilisateur choisit pendant la création.
class TontineDraft {
  // Étape 1
  String model = 'quartier';
  bool customAll = false; // « Je veux tout régler moi-même »

  // Étape 2
  String name = '';
  String description = '';
  bool isPrivate = true;
  bool validateMembers = true;
  int minMembers = 6;
  int maxMembers = 15;

    // Étape 3
  int amount = 20000;
  bool multiParts = false;
  String frequency = 'monthly'; // weekly, biweekly, monthly, other
  int deadlineDay = 25; // jour du mois (rythme mensuel)
  int deadlineWeekday = 0; // 0 = lundi ... 6 = dimanche
  String deadlineHour = '18:00';

  // Étape 4
  String orderMode = 'draw'; // draw, chosen, negotiated
  bool allowSwap = true;
  String collector = 'treasurer'; // treasurer, beneficiary
  String payout = 'immediate'; // immediate, fixedDate
  bool requireUpToDate = true;
  int solidarityPercent = 0;

  // Étape 5
  final Set<String> roles = {'Président', 'Trésorier', 'Censeur'};
  final List<String> customRoles = [];
  final Set<String> heldRoles = {};

    // Réglages des deux étapes optionnelles (« tout régler moi-même »).
  // Valeurs par défaut reprises de la maquette du résumé.

  // Membres
  bool joinMidCycle = false; // arriver en cours de cycle
  bool leaveEarly = false; // partir avant la fin
  bool allowReplacement = true; // remplacer un membre
  String deathRule = 'La place passe à un proche';

  // Retards et impayés
  int lateDelayDays = 3;
  int lateFeePerDay = 1000;
  int lateFeeCap = 10000;
  String absencePenalty = 'Aucune pénalité';
  String nonPaymentRule = 'On retient sur son prochain tour';
  bool autoReminders = true;

  // Argent liquide
  bool cashWitness = false;
  bool cashDoubleValidation = false;
  int cashConfirmHours = 48;
  bool cashCheckEveryMeeting = false;

  // Décisions du groupe
  int voteMinPresencePercent = 50;
  String voteMajority = 'Plus de la moitié';
  int voteDurationHours = 48;
}