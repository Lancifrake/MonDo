import 'package:flutter/foundation.dart';
import '../utils/rules_format.dart';
import 'catalog_data.dart';
import 'mock_data.dart';
import 'payments_data.dart';

/// Tout ce qui change pendant l'utilisation de l'app.
/// Quand on modifie quelque chose, `notifyListeners()` prévient les écrans
/// qui l'affichent : ils se redessinent tout seuls.
class AppState extends ChangeNotifier {
  final List<Tontine> _tontines = [...tontines]; // copie modifiable
  final List<IncomingPayment> _payments = demoPayments();
  final Map<String, Declaration> _declarations = {}; // une par tontine
  int _receiptCounter = 143; // le prochain reçu sera le n° 144

  // ---------- Mes tontines ----------

  List<Tontine> get myTontines => List.unmodifiable(_tontines);

  int get toPayCount => _tontines
      .where((t) => !t.preparing && t.status == PaymentStatus.aPayer)
      .length;

  int get preparingCount => _tontines.where((t) => t.preparing).length;

  /// Appelé quand je rejoins une tontine : elle arrive en tête de la liste.
  void joinTontine(CatalogTontine t) {
    if (_tontines.any((x) => x.name == t.name)) return; // déjà membre

    _tontines.insert(
      0,
      Tontine(
        name: t.name,
        frequency: frequencyLabel(t.frequency),
        members: t.members,
        totalMembers: t.maxMembers,
        amount: t.amount,
        status: PaymentStatus.aJour,
        progress: (t.members / t.maxMembers).clamp(0.0, 1.0),
        preparing: true,
      ),
    );
    notifyListeners();
  }

  // ---------- Ma cotisation à payer ----------

  /// La déclaration que j'ai envoyée pour cette tontine (null = pas encore).
  Declaration? declarationFor(String group) => _declarations[group];

  /// Appelé quand j'envoie ma déclaration de paiement.
  void declarePayment(Declaration d) {
    _declarations[d.group] = d;

    // La tontine passe de « À payer » à « En attente de validation »
    final i = _tontines.indexWhere((t) => t.name == d.group);
    if (i != -1) {
      _tontines[i] = _tontines[i].withStatus(PaymentStatus.enAttente);
    }
    notifyListeners();
  }

  // ---------- Paiements à valider ----------

  List<IncomingPayment> get pendingPayments =>
      _payments.where((p) => p.decision == PaymentDecision.pending).toList();

  List<IncomingPayment> get processedPayments =>
      _payments.where((p) => p.decision != PaymentDecision.pending).toList();

  int get pendingCount => pendingPayments.length;

  void validatePayment(IncomingPayment p) {
    _receiptCounter++;
    p.decision = PaymentDecision.validated;
    p.receiptNumber = 'MD-2026-${_receiptCounter.toString().padLeft(6, '0')}';
    notifyListeners();
  }

  void rejectPayment(IncomingPayment p, String reason) {
    p.decision = PaymentDecision.rejected;
    p.rejectReason = reason;
    notifyListeners();
  }
}

/// L'unique instance, utilisable depuis n'importe quel écran.
final appState = AppState();