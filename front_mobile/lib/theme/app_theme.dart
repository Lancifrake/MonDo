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

  static ThemeData get light => _construire(Palette.clair, Brightness.light);
  static ThemeData get dark => _construire(Palette.sombre, Brightness.dark);

  static ThemeData _construire(Palette c, Brightness luminosite) {
    final base = ThemeData(useMaterial3: true, brightness: luminosite);
    return ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      colorScheme: ColorScheme.fromSeed(seedColor: c.green, brightness: luminosite).copyWith(
        primary: c.green,
        onPrimary: Colors.white,
        surface: c.surface,
        onSurface: c.textDark,
        surfaceTint: Colors.transparent,
        // Rouge : ce qui bloque (champ invalide). L'orange reste réservé à « une action est attendue ».
        error: c.rouge,
      ),
      scaffoldBackgroundColor: c.background,
      textTheme: base.textTheme.apply(bodyColor: c.textDark, displayColor: c.textDark),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: c.textDark,
        systemOverlayStyle: luminosite == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textDark),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rayon.md),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(Toucher.bouton),
          shape: _forme,
          textStyle: _texteBouton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textDark,
          side: BorderSide(color: c.border),
          minimumSize: const Size.fromHeight(Toucher.bouton),
          shape: _forme,
          textStyle: _texteBouton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        // La nuit, le vert des boutons pleins est trop sombre pour du texte : on l'éclaircit.
        style: TextButton.styleFrom(
          foregroundColor: luminosite == Brightness.dark ? const Color(0xFF6CC79C) : c.green,
          textStyle: _texteBouton,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.textDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rayon.sm)),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textDark,
        contentTextStyle: TextStyle(color: c.surface, fontSize: 14),
        actionTextColor: c.surface,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(color: c.surface, surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: c.surface),
      // Un seul retour dans toute l'app : le chevron, quelle que soit la plateforme.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.chevron_left, size: 32),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: c.hint),
        helperStyle: TextStyle(fontSize: 13, color: c.textMuted),
        errorStyle: TextStyle(fontSize: 13, color: c.rouge),
        border: _border(c.border),
        enabledBorder: _border(c.border),
        focusedBorder: _border(c.green, width: 1.5),
        errorBorder: _border(c.rouge),
        focusedErrorBorder: _border(c.rouge, width: 1.5),
      ),
    );
  }
}
