enum PaymentStatus { aPayer, aJour, enAttente }

class Tontine {
  const Tontine({
    required this.name,
    required this.frequency,
    required this.members,
    required this.totalMembers,
    required this.amount,
    required this.status,
    this.isTreasurer = false,
    this.progress = 0.75,
    this.preparing = false,
  });

  final String name;
  final String frequency;
  final int members;
  final int totalMembers;
  final int amount;
  final PaymentStatus status;
  final bool isTreasurer;
  final double progress; // entre 0 et 1
  final bool preparing; // tontine qui n'a pas encore démarré

  // Même tontine avec un autre statut de paiement
  Tontine withStatus(PaymentStatus newStatus) => Tontine(
        name: name,
        frequency: frequency,
        members: members,
        totalMembers: totalMembers,
        amount: amount,
        status: newStatus,
        isTreasurer: isTreasurer,
        progress: progress,
        preparing: preparing,
      );
}

class Echeance {
  const Echeance({
    required this.day,
    required this.month,
    required this.title,
    required this.subtitle,
  });

  final String day;
  final String month;
  final String title;
  final String subtitle;
}

const tontines = <Tontine>[
  Tontine(
    name: 'Les Bâtisseurs de Bonamoussadi',
    frequency: 'Chaque mois',
    members: 12,
    totalMembers: 15,
    amount: 450000,
    status: PaymentStatus.aPayer,
  ),
  Tontine(
    name: 'Femmes Dynamiques',
    frequency: 'Chaque mois',
    members: 8,
    totalMembers: 18,
    amount: 150000,
    status: PaymentStatus.aJour,
  ),
  Tontine(
    name: 'Famille & Projets',
    frequency: 'Chaque mois',
    members: 8,
    totalMembers: 15,
    amount: 180000,
    status: PaymentStatus.aJour,
    isTreasurer: true,
  ),
];

const echeances = <Echeance>[
  Echeance(
    day: '25',
    month: 'JUN',
    title: 'Cotisation · Bâtisseurs',
    subtitle: '50 000 FCFA',
  ),
  Echeance(
    day: '28',
    month: 'JUN',
    title: 'Réunion mensuelle',
    subtitle: 'Chez Marie, Bonamoussadi · 16h',
  ),
  Echeance(
    day: '05',
    month: 'JUL',
    title: 'Cotisation · Femmes Dynamiques',
    subtitle: '25 000 FCFA',
  ),
];