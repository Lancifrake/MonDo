import 'group_data.dart';
import 'tontine_draft.dart';

enum JoinMode { onRequest, open }

class CatalogTontine {
  const CatalogTontine({
    required this.name,
    required this.city,
    required this.organizer,
    required this.description,
    required this.members,
    required this.joinMode,
    required this.rules,
    this.inviteCode,
    this.progress,
  });

  final String name;
  final String city;
  final String organizer;
  final String description;
  final int members; // membres déjà inscrits
  final JoinMode joinMode;
  final TontineDraft rules; // toutes les règles de la tontine
  final String? inviteCode; // null = tontine publique
  final TontineProgress? progress; // null = tontine en préparation

  bool get isPrivate => inviteCode != null;
  bool get isRunning => progress != null;
  int get amount => rules.amount;
  String get frequency => rules.frequency;
  int get maxMembers => rules.maxMembers;
}

/// Cherche une tontine à partir d'un code d'invitation.
CatalogTontine? findByInviteCode(String code) {
  final wanted = code.trim().toUpperCase();
  if (wanted.isEmpty) return null;
  for (final t in catalogTontines) {
    if (t.inviteCode == wanted) return t;
  }
  return null;
}

/// Cherche le groupe d'une tontine de l'accueil à partir de son nom.
CatalogTontine? findGroupByName(String name) {
  for (final t in catalogTontines) {
    if (t.name == name) return t;
  }
  return null;
}

final catalogTontines = <CatalogTontine>[
  CatalogTontine(
    name: 'Commerçants du Marché Congo',
    city: 'Douala',
    organizer: 'Marc Tchoumi',
    description:
        "Des commerçants du marché qui cotisent chaque semaine. "
        "L'organisateur valide chaque demande.",
    members: 9,
    joinMode: JoinMode.onRequest,
    rules: TontineDraft()
      ..amount = 25000
      ..frequency = 'weekly'
      ..deadlineWeekday = 4
      ..minMembers = 6
      ..maxMembers = 15,
  ),
  CatalogTontine(
    name: 'Les Ambitieuses de Yaoundé',
    city: 'Yaoundé',
    organizer: 'Rita Owona',
    description:
        "Un groupe de femmes entrepreneures. "
        "Entrée libre tant qu'il reste des places.",
    members: 14,
    joinMode: JoinMode.open,
    rules: TontineDraft()
      ..amount = 50000
      ..frequency = 'monthly'
      ..deadlineDay = 25
      ..minMembers = 10
      ..maxMembers = 20
      ..lateDelayDays = 5,
  ),
  CatalogTontine(
    name: 'Jeunes Entrepreneurs de Bonanjo',
    city: 'Douala',
    organizer: 'Cyrille Biyick',
    description:
        "Un groupe de jeunes entrepreneurs de Bonanjo. "
        "L'organisateur valide chaque demande.",
    members: 6,
    joinMode: JoinMode.onRequest,
    rules: TontineDraft()
      ..amount = 100000
      ..frequency = 'monthly'
      ..minMembers = 5
      ..maxMembers = 10,
  ),
  // Tontine privée : visible seulement avec son code d'invitation
  CatalogTontine(
    name: 'Famille Mbarga',
    city: 'Douala',
    organizer: 'Serge Mbarga',
    description: 'Tontine familiale, uniquement sur invitation.',
    members: 6,
    joinMode: JoinMode.open,
    inviteCode: 'FAMILLE-1103',
    rules: TontineDraft()
      ..amount = 20000
      ..frequency = 'monthly'
      ..deadlineDay = 25
      ..minMembers = 6
      ..maxMembers = 12
      ..lateDelayDays = 5
      ..lateFeePerDay = 0
      ..lateFeeCap = 0,
  ),
  // Une tontine déjà démarrée, dont je fais partie (« Mes tontines »)
  CatalogTontine(
    name: 'Femmes Dynamiques',
    city: 'Douala',
    organizer: 'Rose Ekani',
    description: 'Un groupe de femmes qui cotisent chaque mois.',
    members: 8,
    joinMode: JoinMode.open,
    inviteCode: 'FEMMES-2210',
    rules: TontineDraft()
      ..amount = 25000
      ..frequency = 'monthly'
      ..deadlineDay = 25
      ..minMembers = 6
      ..maxMembers = 18,
    progress: const TontineProgress(
      currentTurn: 4,
      collectedPercent: 75,
      pot: 150000,
      potTarget: 200000,
      paidThisTurn: true,
      me: 'Amina N.',
      seed: 'FEMDY-2026-00A1',
      order: [
        'Carole B.',
        'Léa N.',
        'Nadège F.',
        'Rose F.',
        'Sandra M.',
        'Amina N.',
        'Aïcha K.',
        'Estelle K.',
      ],
      payers: [
        PayerStatus('Léa N.', PayStatus.pending),
        PayerStatus('Nadège F.', PayStatus.late),
        PayerStatus('Sandra M.', PayStatus.paid),
        PayerStatus('Aïcha K.', PayStatus.paid),
        PayerStatus('Carole B.', PayStatus.paid),
        PayerStatus('Rose F.', PayStatus.paid),
      ],
      hiddenPayers: 2,
      ledger: [
        LedgerEntry(
          number: 141,
          label: 'Cotisation · Amina N.',
          hash: 'a91f…83c2',
          previous: '7be4…d18a',
        ),
        LedgerEntry(
          number: 140,
          label: 'Cotisation · Boris T.',
          hash: '7be4…d18a',
          previous: 'c03d…9e71',
        ),
        LedgerEntry(
          number: 139,
          label: 'Cotisation · Clarisse N.',
          hash: 'c03d…9e71',
          previous: '1f58…a2b0',
        ),
      ],
    ),
  ),
];