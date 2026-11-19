import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Une palette par mode. Les teintes de marque (vert foncé du grand rectangle, citron) ne changent pas :
/// seuls les fonds, les textes, les traits et les accents s'adaptent au mode sombre.
class Palette {
  const Palette({
    required this.green,
    required this.vertEncre,
    required this.background,
    required this.surface,
    required this.textDark,
    required this.textMuted,
    required this.link,
    required this.border,
    required this.limeSoft,
    required this.mint,
    required this.amberBg,
    required this.amberText,
    required this.blueBg,
    required this.track,
    required this.pinkBg,
    required this.pinkText,
    required this.hint,
    required this.disabled,
    required this.switchOff,
    required this.surfaceNeutre,
    required this.action,
    required this.rouge,
    required this.violet,
  });

  final Color green, vertEncre, background, surface, textDark, textMuted, link, border, limeSoft, mint;
  final Color amberBg, amberText, blueBg, track, pinkBg, pinkText, hint, disabled, switchOff, surfaceNeutre;
  final Color action, rouge, violet;

  static const clair = Palette(
    green: Color(0xFF1F6B4F),
    vertEncre: Color(0xFF0F3D2E),
    background: Color(0xFFF7F7F2),
    surface: Color(0xFFFFFFFF),
    textDark: Color(0xFF14231C),
    textMuted: Color(0xFF5F6B65),
    link: Color(0xFF2E6F95),
    border: Color(0xFFDDE1D9),
    limeSoft: Color(0xFFEEF5C6),
    mint: Color(0xFFE3EFE6),
    amberBg: Color(0xFFFCF0C8),
    amberText: Color(0xFF8A5A00),
    blueBg: Color(0xFFDCEAF6),
    track: Color(0xFFE3E7E0),
    pinkBg: Color(0xFFF9DCE3),
    pinkText: Color(0xFFB23A5C),
    hint: Color(0xFF6F7973),
    disabled: Color(0xFFB3B9B5),
    switchOff: Color(0xFFD9DDD6),
    surfaceNeutre: Color(0xFFE6ECE6),
    // Action attendue : vert vif (l'orange ne s'accordait pas avec l'app).
    action: Color(0xFF17845A),
    rouge: Color(0xFFC62828),
    violet: Color(0xFF6D4AFF),
  );

  /// Nuit : fond vert-noir (pas du noir pur), cartes un cran plus claires, textes et accents éclaircis
  /// pour garder au moins 4,5:1 sur les cartes.
  static const sombre = Palette(
    green: Color(0xFF2E8862),
    vertEncre: Color(0xFFA9D8BF),
    background: Color(0xFF0E1411),
    surface: Color(0xFF18201C),
    textDark: Color(0xFFE6ECE8),
    textMuted: Color(0xFFA0ADA6),
    link: Color(0xFF86BCDF),
    border: Color(0xFF2B3631),
    limeSoft: Color(0xFF2E3517),
    mint: Color(0xFF1C2E24),
    amberBg: Color(0xFF3A2E10),
    amberText: Color(0xFFF2C463),
    blueBg: Color(0xFF1A2C3A),
    track: Color(0xFF2B3631),
    pinkBg: Color(0xFF3A1C25),
    pinkText: Color(0xFFF08AA6),
    hint: Color(0xFF8A968F),
    disabled: Color(0xFF4E5852),
    switchOff: Color(0xFF3A4540),
    surfaceNeutre: Color(0xFF222B26),
    action: Color(0xFF6CC79C),
    rouge: Color(0xFFF07272),
    violet: Color(0xFFA592FF),
  );
}

class AppColors {
  /// Mode en cours, réglé par l'app selon le réglage du téléphone (voir main.dart).
  static bool sombre = false;
  static Palette get _p => sombre ? Palette.sombre : Palette.clair;

  // Teintes de marque, identiques dans les deux modes : grand rectangle, accueil, logo.
  static const darkGreen = Color(0xFF0F3D2E);
  static const lime = Color(0xFFD9EE6E);

  /// Couleur des barres système (heure, batterie) sur un écran au fond de l'app.
  static SystemUiOverlayStyle get barreSysteme => sombre ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  static Color get green => _p.green;

  /// Vert foncé employé comme encre (icône, point du cercle) : s'éclaircit la nuit.
  static Color get vertEncre => _p.vertEncre;
  static Color get background => _p.background;

  /// Fond des cartes, champs et barre d'onglets (blanc le jour).
  static Color get surface => _p.surface;
  static Color get textDark => _p.textDark;
  static Color get textMuted => _p.textMuted;
  static Color get link => _p.link;
  static Color get border => _p.border;
  static Color get limeSoft => _p.limeSoft;
  static Color get mint => _p.mint;
  static Color get amberBg => _p.amberBg;
  static Color get amberText => _p.amberText;
  static Color get blueBg => _p.blueBg;
  static Color get track => _p.track;
  static Color get pinkBg => _p.pinkBg;
  static Color get pinkText => _p.pinkText;

  /// Texte indicatif des champs : 4,5:1 sur la surface, plus clair que [textMuted].
  static Color get hint => _p.hint;

  /// Élément désactivé (icône, piste d'interrupteur éteint).
  static Color get disabled => _p.disabled;
  static Color get switchOff => _p.switchOff;

  /// Fond neutre d'une case non saisissable (indicatif du pays).
  static Color get surfaceNeutre => _p.surfaceNeutre;

  /// Accents : vert vif = action attendue, violet = ce qui croît, rouge = danger ou dû à traiter.
  static Color get action => _p.action;
  static Color get rouge => _p.rouge;
  static Color get violet => _p.violet;
  static Color get encre => _p.textDark;
}
