enum ActivityKind { contribution, payout }

class Receipt {
  const Receipt({
    required this.number,
    required this.hash,
    required this.group,
    required this.turn,
    required this.amount,
    required this.payer,
    required this.mode,
    required this.date,
    this.receivedBy,
    this.reference,
  });

  final String number; // MD-2026-000138
  final String hash; // empreinte abrégée : 0095…d84b
  final String group;
  final int turn;
  final int amount;
  final String payer;
  final String mode; // Espèces, Mobile Money
  final String date;
  final String? receivedBy; // paiement en espèces : qui a reçu l'argent
  final String? reference; // paiement Mobile Money : référence de l'opérateur

  String get groupLabel => '$group · tour $turn';
}

class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.title,
    required this.group,
    required this.date,
    required this.amount,
    this.receipt,
  });

  final ActivityKind kind;
  final String title;
  final String group;
  final String date;
  final int amount; // négatif = j'ai payé, positif = j'ai reçu
  final Receipt? receipt; // seulement pour une cotisation validée

  String get subtitle => '$group · $date';
}

const receiptFemmes = Receipt(
  number: 'MD-2026-000138',
  hash: '0095…d84b',
  group: 'Femmes Dynamiques',
  turn: 4,
  amount: 25000,
  payer: 'Amina N.',
  mode: 'Espèces',
  receivedBy: 'Carole B.',
  date: '16 juin',
);

const receiptBatisseurs = Receipt(
  number: 'MD-2026-000130',
  hash: 'be01…ae75',
  group: 'Les Bâtisseurs',
  turn: 5,
  amount: 50000,
  payer: 'Amina N.',
  mode: 'Mobile Money',
  reference: 'MP2406041022',
  date: '4 juin',
);

const activityItems = <ActivityItem>[
  ActivityItem(
    kind: ActivityKind.contribution,
    title: 'Cotisation · validée',
    group: 'Femmes Dynamiques',
    date: '16 juin',
    amount: -25000,
    receipt: receiptFemmes,
  ),
  ActivityItem(
    kind: ActivityKind.contribution,
    title: 'Cotisation · validée',
    group: 'Les Bâtisseurs',
    date: '4 juin',
    amount: -50000,
    receipt: receiptBatisseurs,
  ),
  ActivityItem(
    kind: ActivityKind.payout,
    title: 'Tour reçu',
    group: 'Famille & Projets',
    date: '10 juin',
    amount: 300000,
  ),
];

/// Tous mes reçus : les cotisations de l'activité qui en ont un.
List<Receipt> get myReceipts => [
      for (final item in activityItems)
        if (item.receipt != null) item.receipt!,
    ];