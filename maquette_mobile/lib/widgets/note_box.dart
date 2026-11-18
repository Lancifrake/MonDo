import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NoteBox extends StatelessWidget {
  const NoteBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFE9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}