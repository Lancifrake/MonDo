/// Échelle d'espacement commune (en points logiques) : on ne prend que ces valeurs.
class Espace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// Marge latérale des écrans.
  static const ecran = 20.0;

  /// Écart entre une icône de ligne (24) et son texte : le texte commence toujours au même endroit.
  static const iconeTexte = 24.0;

  /// Retrait d'un trait de séparation sous une ligne à icône : marge + icône + écart.
  static double retraitTrait(double marge) => marge + 24 + iconeTexte;
}

/// Rayons d'angle : petit (touches), moyen (champs, boutons, cartes), grand (cartes mises en avant).
class Rayon {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 22.0;
}

/// Tailles de zones tactiles.
class Toucher {
  /// Minimum Android (48), au-dessus du minimum iOS (44).
  static const min = 48.0;

  /// Hauteur des boutons principaux.
  static const bouton = 56.0;
}
