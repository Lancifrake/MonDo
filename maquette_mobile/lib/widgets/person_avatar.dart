import 'package:flutter/material.dart';

class _Tint {
  const _Tint(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

// Couleurs utilisées à tour de rôle
const _tints = [
  _Tint(Color(0xFFF9DCE3), Color(0xFFB23A5C)),
  _Tint(Color(0xFFDCEAF6), Color(0xFF2E6F95)),
  _Tint(Color(0xFFE6E0F5), Color(0xFF6C5BA8)),
  _Tint(Color(0xFFFCE8CF), Color(0xFFB36B1A)),
  _Tint(Color(0xFFE3EFE6), Color(0xFF1F6B4F)),
];

String initialsOf(String name) {
  final parts = name.replaceAll('.', '').split(' ');
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.index = 0,
    this.radius = 20,
  });

  final String name;
  final int index; // sert à choisir la couleur
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tint = _tints[index % _tints.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: tint.background,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: tint.foreground,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }
}