import 'package:flutter/material.dart';

/// Statut en texte seul, sans pastille de fond (règle commune avec la console d'administration).
/// [background] est ignoré : gardé pour ne pas casser les appels existants.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.background,
    required this.foreground,
  });

  final String label;
  final Color? background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground));
  }
}
