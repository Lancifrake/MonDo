import 'package:intl/intl.dart';

String formatAmount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formate une date ISO 8601 en format lisible (ex: 15 nov 2026)
const _moisCourts = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Sans dépendre des données de langue d'intl (non chargées, le format échouait en silence).
String formatDate(String isoDate) {
  final d = DateTime.tryParse(isoDate)?.toLocal();
  if (d == null) return isoDate;
  return '${d.day} ${_moisCourts[d.month - 1]} ${d.year}';
}

/// Formate une date-heure en format relatif (ex: "il y a 2 heures")
String formatDateTimeRelative(String isoDate) {
  try {
    final dateTime = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${dateTime.toLocal().day} ${_moisCourts[dateTime.toLocal().month - 1]}';
    }
  } catch (e) {
    return isoDate;
  }
}