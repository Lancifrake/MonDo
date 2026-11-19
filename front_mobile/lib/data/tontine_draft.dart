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
    description: 'Entre voisins : 10 000 FCFA chaque mois.',
  ),
  TontineModel(
    id: 'ressortissants',
    title: 'Association de ressortissants',
    description: 'Entre ressortissants : 10 000 FCFA chaque mois.',
  ),
  TontineModel(
    id: 'eglise',
    title: "Groupe d'église",
    description: 'Petites sommes chaque semaine : 2 000 FCFA.',
  ),
  TontineModel(
    id: 'commercants',
    title: 'Tontine de commerçants',
    description: 'Chaque semaine, montants élevés : 50 000 FCFA.',
  ),
  TontineModel(
    id: 'scolarite',
    title: 'Caisse pour la scolarité',
    description: 'Chaque mois, 15 000 FCFA, pour la rentrée.',
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
  int periodeJours = 10; // si frequence == 'jours'

  // Options avancées
  int? scoreMinimum; // tontine ouverte : score exigé pour entrer
  bool rappels = true; // rappels 3 jours et 1 jour avant l'échéance
  bool parrainageAccepte = false;
  int? placeSouhaitee; // null = dernière place, toujours permise

  // Ordre fixé par l'organisateur (tontine privée seulement) : qui reçoit à quel tour.
  bool ordreFixe = false;
  int maPlaceFixee = 1;
  List<String> identifiants = List.filled(6, ''); // un par tour ; celui de ma place est ignoré

  /// Garde une case par membre quand le nombre de membres change.
  void ajusterOrdre() {
    if (identifiants.length != nombreMembres) {
      identifiants = List.generate(nombreMembres, (i) => i < identifiants.length ? identifiants[i] : '');
    }
    if (maPlaceFixee > nombreMembres) maPlaceFixee = nombreMembres;
  }

  static final _formeIdentifiant =
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// Ce qui manque pour signer l'ordre fixé, ou null s'il est complet.
  String? problemeOrdre(String? monId) {
    if (!isPrivate || !ordreFixe) return null;
    ajusterOrdre();
    final vus = <String>{if (monId != null) monId.toLowerCase()};
    for (var i = 0; i < nombreMembres; i++) {
      if (i + 1 == maPlaceFixee) continue;
      final id = identifiants[i].trim().toLowerCase();
      if (id.isEmpty) return 'Il manque le membre de la place ${i + 1}';
      if (!_formeIdentifiant.hasMatch(id)) return 'Place ${i + 1} : ce n’est pas un identifiant MonDo';
      if (!vus.add(id)) return 'Place ${i + 1} : ce membre est déjà dans la liste';
    }
    return null;
  }

  /// L'ordre à signer : un identifiant par tour, null à ma place (le service y met le mien).
  List<String?>? get ordreASigner => isPrivate && ordreFixe
      ? [for (var i = 0; i < nombreMembres; i++) i + 1 == maPlaceFixee ? null : identifiants[i].trim().toLowerCase()]
      : null;

  /// Le délai de grâce doit être plus court que la période (règle du serveur).
  int get graceMax => switch (frequence) {
        'hebdomadaire' => 6,
        'jours' => periodeJours - 1,
        _ => 27,
      };

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