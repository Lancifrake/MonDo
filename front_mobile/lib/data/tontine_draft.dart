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
}