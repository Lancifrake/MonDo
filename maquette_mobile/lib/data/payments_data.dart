// ---------- Paiements que je dois valider (trésorier) ----------

enum PaymentDecision { pending, validated, rejected }

class IncomingPayment {
  IncomingPayment({
    required this.id,
    required this.payer,
    required this.group,
    required this.when,
    required this.amount,
    this.receivedBy,
    this.reference,
  });

  final int id;
  final String payer;
  final String group;
  final String when; // « Auj. 08:15 »
  final int amount;
  final String? receivedBy; // paiement en espèces : qui a reçu l'argent
  final String? reference; // paiement Mobile Money : référence de l'opérateur

  // Ces trois champs changent quand je valide ou je refuse
  PaymentDecision decision = PaymentDecision.pending;
  String? receiptNumber; // si validé
  String? rejectReason; // si refusé
}

// Paiements de démonstration (une fonction : chaque appel crée de nouveaux objets)
List<IncomingPayment> demoPayments() => [
      IncomingPayment(
        id: 1,
        payer: 'Joël M.',
        group: 'Famille & Projets',
        when: 'Auj. 08:15',
        amount: 30000,
        receivedBy: 'Amina N.',
      ),
      IncomingPayment(
        id: 2,
        payer: 'Estelle K.',
        group: 'Famille & Projets',
        when: 'Auj. 07:40',
        amount: 30000,
        reference: 'OM2406180711',
      ),
    ];

// ---------- Ma cotisation à payer et ma déclaration ----------

enum PayMode { mobileMoney, cash }

/// La cotisation que je dois payer en ce moment.
class DueContribution {
  const DueContribution({
    required this.group,
    required this.turn,
    required this.amount,
    required this.collector,
    required this.deadline,
  });

  final String group;
  final int turn;
  final int amount;
  final String collector; // la personne qui encaisse (trésorier)
  final String deadline; // « le 25 du mois à 18:00 »
}

// Donnée de démonstration (elle viendra du serveur)
const nextDue = DueContribution(
  group: 'Les Bâtisseurs de Bonamoussadi',
  turn: 6,
  amount: 50000,
  collector: 'Marie T.',
  deadline: 'le 25 du mois à 18:00',
);

/// Le paiement que j'ai déclaré, en attente de validation par la personne qui encaisse.
class Declaration {
  const Declaration({
    required this.group,
    required this.turn,
    required this.amount,
    required this.mode,
    required this.payer,
    this.reference,
  });

  final String group;
  final int turn;
  final int amount;
  final PayMode mode;
  final String payer;
  final String? reference; // seulement pour Mobile Money

  String get groupLabel => '$group · tour $turn';
  String get modeLabel =>
      mode == PayMode.mobileMoney ? 'Mobile Money' : 'Espèces';
}