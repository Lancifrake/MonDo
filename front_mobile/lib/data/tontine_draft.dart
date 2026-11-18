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

/// Tout ce que l'utilisateur choisit pendant la création : c'est le règlement
/// que l'organisateur signera (docs/conception/api.md, POST /cercles).
class TontineDraft {
  // Étape 1
  String model = 'quartier';
  bool customAll = false; // « Je veux tout régler moi-même »

  // Étape 2
  bool isPrivate = true;
  int montant = 10000; // FCFA par membre et par tour
  int nombreMembres = 6; // 3 à 50

  // Étape 3
  String frequence = 'mensuelle'; // hebdomadaire ou mensuelle
  DateTime datePremierTour = DateTime.now().add(const Duration(days: 7));
  int penaliteRetard = 500;
  int delaiGraceJours = 3;

  /// Le délai de grâce doit être plus court que la période (règle du serveur).
  int get graceMax => frequence == 'hebdomadaire' ? 6 : 27;

  /// Règles prêtes selon le modèle choisi.
  void appliquerModele(String id) {
    model = id;
    switch (id) {
      case 'eglise':
        frequence = 'hebdomadaire';
        montant = 2000;
        delaiGraceJours = 2;
      case 'commercants':
        frequence = 'hebdomadaire';
        montant = 50000;
        delaiGraceJours = 1;
      case 'scolarite':
        frequence = 'mensuelle';
        montant = 15000;
      default:
        frequence = 'mensuelle';
        montant = 10000;
        delaiGraceJours = 3;
    }
    if (delaiGraceJours > graceMax) delaiGraceJours = graceMax;
  }
}