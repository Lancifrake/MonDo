class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.identityLevel,
    required this.offer,
  });

  final String name;
  final String phone;
  final int identityLevel; // 1 = basique, 2 = identité vérifiée
  final String offer; // nom de l'offre actuelle
}

// Données de démonstration : elles viendront du serveur
const demoUser = UserProfile(
  name: 'Amina Njoya',
  phone: '+237 699685376',
  identityLevel: 1,
  offer: 'Premium',
);