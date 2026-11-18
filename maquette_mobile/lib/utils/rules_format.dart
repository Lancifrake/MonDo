import '../data/tontine_draft.dart';
import 'format.dart';

const _weekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

String yesNo(bool value) => value ? 'Oui' : 'Non';

String fcfa(int value) => '${formatAmount(value)} FCFA';

String frequencyLabel(String frequency) => switch (frequency) {
      'weekly' => 'Chaque semaine',
      'biweekly' => '2 semaines',
      'monthly' => 'Chaque mois',
      _ => 'Autre rythme',
    };

String frequencyPhrase(String frequency) => switch (frequency) {
      'weekly' => 'chaque semaine',
      'biweekly' => 'toutes les 2 semaines',
      'monthly' => 'chaque mois',
      _ => 'selon le rythme choisi',
    };

// « le 25 du mois », « le lundi »... ou null si le rythme est libre
String? deadlinePhrase(TontineDraft d) {
  switch (d.frequency) {
    case 'monthly':
      return 'le ${d.deadlineDay} du mois';
    case 'weekly':
    case 'biweekly':
      return 'le ${_weekdays[d.deadlineWeekday].toLowerCase()}';
    default:
      return null;
  }
}

String deadlineValue(TontineDraft d) {
  final phrase = deadlinePhrase(d);
  return phrase == null ? 'À définir' : '$phrase à ${d.deadlineHour}';
}

String orderLabel(String mode) => switch (mode) {
      'chosen' => 'Ordre choisi',
      'negotiated' => 'Ordre négocié',
      _ => 'Tirage au sort',
    };

// Se complète dans une phrase : « L'ordre des tours est ... »
String orderPhrase(String mode) => switch (mode) {
      'chosen' => "fixé à l'avance par l'organisateur",
      'negotiated' => 'négocié entre les membres',
      _ => 'tiré au sort devant tout le monde',
    };

// « 5 jours de délai, puis : 1 000 FCFA par jour de retard. »
// ou « 5 jours de délai, puis : aucune pénalité. »
String latePhrase(TontineDraft d) {
  final penalty = d.lateFeePerDay == 0
      ? 'aucune pénalité'
      : '${fcfa(d.lateFeePerDay)} par jour de retard';
  return '${d.lateDelayDays} jours de délai, puis : $penalty.';
}