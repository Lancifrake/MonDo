import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground = Colors.white,
    this.borderColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed; // null = bouton désactivé
  final Color? background; // vert de l'app par défaut
  final Color foreground;
  final Color? borderColor;
  final bool isLoading; // affiche une roue et bloque le bouton

  @override
  Widget build(BuildContext context) {
    final background = this.background ?? AppColors.green;
    return SizedBox(
      width: double.infinity,
      height: Toucher.bouton,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          // La nuit, un texte vif sur fond estompé ferait croire le bouton actif : on l'estompe aussi.
          disabledForegroundColor: AppColors.sombre ? foreground.withValues(alpha: 0.45) : foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rayon.md),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
              )
            : Text(label),
      ),
    );
  }
}