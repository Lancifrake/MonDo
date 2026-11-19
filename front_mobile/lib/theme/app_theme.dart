import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Police système (San Francisco sur iPhone, Roboto sur Android), graisses à 600 au plus,
/// pas de fond coloré décoratif : mêmes règles que la console d'administration.
class AppTheme {
  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Rayon.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static final _forme = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.md));
  static const _texteBouton = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green).copyWith(
        primary: AppColors.green,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
        // Rouge : ce qui bloque (champ invalide). L'orange reste réservé à « une action est attendue ».
        error: AppColors.rouge,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textDark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(Toucher.bouton),
          shape: _forme,
          textStyle: _texteBouton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(Toucher.bouton),
          shape: _forme,
          textStyle: _texteBouton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.green, textStyle: _texteBouton),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.textDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.sm)),
        showCheckmark: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white),
      // Un seul retour dans toute l'app : le chevron, quelle que soit la plateforme.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.chevron_left, size: 32),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.hint),
        helperStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        errorStyle: const TextStyle(fontSize: 13, color: AppColors.rouge),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.green, width: 1.5),
        errorBorder: _border(AppColors.rouge),
        focusedErrorBorder: _border(AppColors.rouge, width: 1.5),
      ),
    );
  }
}
