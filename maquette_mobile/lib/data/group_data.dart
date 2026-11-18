class Right {
  const Right(this.label, {this.afterVote = false});

  final String label;
  final bool afterVote; // true = « Après un vote »
}

class GroupRole {
  const GroupRole({
    required this.name,
    required this.holders,
    required this.rights,
  });

  final String name;
  final String holders; // qui tient ce poste
  final List<Right> rights;
}

// Le premier de la liste est le président
const demoMembers = [
  'Rita O.',
  'Hervé N.',
  'Mireille E.',
  'Cyrille B.',
  'Joséphine E.',
  'Alain M.',
  'Thierry A.',
  'Nadège T.',
  'Blaise K.',
  'Carine M.',
  'Ulrich F.',
  'Estelle B.',
  'Aïcha N.',
  'Gaston L.',
];

const groupRoles = <GroupRole>[
  GroupRole(
    name: 'Président',
    holders: 'Rita O.',
    rights: [
      Right("Voir l'argent du groupe"),
      Right("Dire qu'on a payé"),
      Right('Annuler un paiement', afterVote: true),
      Right('Contester un paiement'),
      Right('Changer les règles du groupe', afterVote: true),
      Right('Inviter et accepter des membres'),
      Right("Exclure quelqu'un", afterVote: true),
      Right('Lancer un vote'),
      Right('Valider le versement au bénéficiaire'),
      Right('Envoyer une annonce'),
      Right('Télécharger les relevés'),
      Right('Gérer les rôles du groupe', afterVote: true),
      Right("Voir l'historique des actions"),
    ],
  ),
  GroupRole(
    name: 'Trésorier',
    holders: "Personne pour l'instant",
    rights: [
      Right("Voir l'argent du groupe"),
      Right("Dire qu'on a payé"),
      Right("Recevoir l'argent et le confirmer"),
      Right('Annuler un paiement', afterVote: true),
      Right('Contester un paiement'),
      Right("Compter l'argent de la caisse"),
      Right('Lancer un vote'),
      Right('Valider le versement au bénéficiaire'),
      Right('Télécharger les relevés'),
    ],
  ),
  GroupRole(
    name: 'Membre',
    holders: 'Tous les membres',
    rights: [
      Right("Voir l'argent du groupe"),
      Right("Dire qu'on a payé"),
      Right('Contester un paiement'),
    ],
  ),
];

enum PayStatus { pending, late, paid }

class PayerStatus {
  const PayerStatus(this.name, this.status);

  final String name;
  final PayStatus status;
}

// Une ligne du « Carnet du groupe » : chaque empreinte est liée à la précédente
class LedgerEntry {
  const LedgerEntry({
    required this.number,
    required this.label,
    required this.hash,
    required this.previous,
  });

  final int number;
  final String label;
  final String hash;
  final String previous;
}

/// L'avancement d'une tontine déjà démarrée.
class TontineProgress {
  const TontineProgress({
    required this.currentTurn,
    required this.collectedPercent,
    required this.pot,
    required this.potTarget,
    required this.paidThisTurn,
    required this.order,
    required this.me,
    required this.seed,
    required this.payers,
    required this.hiddenPayers,
    required this.ledger,
  });

  final int currentTurn; // tour en cours (1 = premier tour)
  final int collectedPercent;
  final int pot; // déjà collecté pour ce tour
  final int potTarget; // objectif du tour
  final bool paidThisTurn; // est-ce que moi, j'ai payé
  final List<String> order; // ordre des tours : le premier reçoit en premier
  final String me; // mon nom dans la liste
  final String seed; // graine publiée du tirage au sort
  final List<PayerStatus> payers; // ceux qu'on affiche
  final int hiddenPayers; // « et 2 autres »
  final List<LedgerEntry> ledger;
  

  int get totalTurns => order.length;
  String get beneficiary => order[currentTurn - 1];
}