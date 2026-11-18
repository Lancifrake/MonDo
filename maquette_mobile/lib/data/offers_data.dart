class Offer {
  const Offer({
    required this.name,
    required this.price,
    required this.features,
    this.isCurrent = false,
    this.actionLabel,
  });

  final String name;
  final String price;
  final List<String> features;
  final bool isCurrent; // « Ton offre »
  final String? actionLabel; // bouton en bas de la carte (facultatif)
}

const offers = <Offer>[
  Offer(
    name: 'Gratuit',
    price: '0 FCFA',
    features: [
      '1 tontine, 15 membres',
      '3 rôles personnalisés',
      'Reçus, rappels, cash et Mobile Money',
    ],
    actionLabel: 'Choisir (aperçu)',
  ),
  Offer(
    name: 'Premium',
    price: 'Prix annoncé bientôt',
    isCurrent: true,
    features: [
      '5 tontines, 50 membres',
      'Autant de rôles que tu veux',
      'Deux validations et vérification de la caisse',
    ],
  ),
  Offer(
    name: 'Organisation',
    price: 'Sur devis',
    features: [
      'Tontines illimitées, 500 membres',
      'Rôles illimités',
      'Accès pour banques et microfinances',
    ],
  ),
];