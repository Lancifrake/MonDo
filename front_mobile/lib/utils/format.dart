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
String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  } catch (e) {
    return isoDate;
  }
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
      return DateFormat('d MMM', 'fr_FR').format(dateTime);
    }
  } catch (e) {
    return isoDate;
  }
}