import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cercles_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sobre.dart';

/// Libellé d'un membre : « moi » ou sa place, le serveur ne donne pas les noms aux membres.
String membreLibelle(Cercle c, String id, String moi) {
  if (id == moi) return 'Moi';
  final p = c.ordre?.where((o) => o.membreId == id).firstOrNull;
  return p == null ? 'Membre ${id.substring(0, 4)}' : 'Place ${p.position}';
}

// ---------------------------------------------------------------- Registre

class RegistreScreen extends ConsumerWidget {
  const RegistreScreen({super.key, required this.cercleId});

  final String cercleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(espaceServiceProvider).registre(cercleId),
      builder: (context, snap) {
        if (snap.hasError) return Ecran(titre: 'Registre', enfants: [Note(messageErreur(snap.error!))]);
        if (!snap.hasData) return const Ecran(titre: 'Registre', enfants: [Squelette()]);
        final r = snap.data!;
        final evenements = (r['evenements'] as List).cast<Map<String, dynamic>>();
        final documents = (r['documents'] as List).cast<Map<String, dynamic>>();
        String objet(String o) => switch (o) {
              'reglement' => 'Règlement signé',
              'engagement' || 'engagements' => 'Engagements des membres',
              'ordre' => 'Ordre de passage figé',
              'cotisation_confirmee' => 'Paiement confirmé',
              'defaut_constate' => 'Défaut constaté',
              'mise_en_demeure' => 'Mise en demeure',
              'echange_de_places' => 'Échange de places',
              'depart' => 'Départ d’un membre',
              'ouverture_litige' => 'Litige ouvert',
              'decision_litige' => 'Litige tranché',
              'fin_cercle' => 'Fin de la tontine',
              _ => o.replaceAll('_', ' '),
            };
        return Ecran(
          titre: 'Registre',
          enfants: [
            Note(r['integre'] == true
                ? 'Intégrité vérifiée : aucun document n’a été modifié depuis son inscription.'
                : 'Attention : l’intégrité du registre n’est pas vérifiée.'),
            const Note('Chaque événement est réduit à une empreinte, puis inscrite par lots sur une chaîne publique.'),
            const Titre('Documents vérifiés'),
            for (final (i, d) in documents.indexed) ...[
              if (i > 0) const TraitRangee(marge: 0),
              RangeeIcone(
                marge: 0,
                icone: d['conforme'] == true ? Icons.verified_outlined : Icons.error_outline,
                couleurIcone: d['conforme'] == true ? AppColors.green : AppColors.orange,
                titre: objet(d['objet'] as String),
                detail: d['conforme'] == true ? 'Conforme à ce qui a été signé' : 'Non conforme',
                accent: d['conforme'] != true,
              ),
            ],
            const Titre('Événements'),
            ListeLimitee(
              nombre: evenements.length,
              marge: 0,
              separateur: const TraitRangee(marge: 0),
              construire: (i) {
                final e = evenements[evenements.length - 1 - i]; // le plus récent d'abord
                return RangeeIcone(
                  marge: 0,
                  icone: e['statut'] == 'inscrite' ? Icons.link : Icons.hourglass_empty,
                  couleurIcone: e['statut'] == 'inscrite' ? AppColors.green : AppColors.textMuted,
                  titre: objet(e['objet'] as String),
                  detail: '${dateCourte(e['enregistreLe'] as String?)} · '
                      '${e['statut'] == 'inscrite' ? 'inscrit sur la chaîne' : 'en attente du lot'}',
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------- Échanges de places

class EchangesScreen extends ConsumerStatefulWidget {
  const EchangesScreen({super.key, required this.cercle});

  final Cercle cercle;

  @override
  ConsumerState<EchangesScreen> createState() => _EchangesState();
}

class _EchangesState extends ConsumerState<EchangesScreen> {
  late Future<List<Map<String, dynamic>>> _liste = ref.read(espaceServiceProvider).echanges(widget.cercle.id);

  Future<void> _faire(Future<Object?> Function() action, String ok) async {
    try {
      await action();
      setState(() => _liste = ref.read(espaceServiceProvider).echanges(widget.cercle.id));
      ref.invalidate(cercleProvider(widget.cercle.id));
      if (mounted) afficherMessage(context, ok);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.read(espaceServiceProvider);
    final c = widget.cercle;
    final ordre = [...?c.ordre]..sort((a, b) => a.position.compareTo(b.position));
    final maPlace = ordre.where((o) => o.membreId == s.moi).firstOrNull?.position;
    return Ecran(
      titre: 'Échanges de places',
      enfants: [
        const Note(
          'Un échange est gratuit. Les deux membres le signent, il expire au bout de 48 h. '
          'Ton score doit permettre la place que tu demandes.',
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _liste,
          builder: (context, snap) {
            if (snap.hasError) return Note(messageErreur(snap.error!));
            if (!snap.hasData) return const Squelette();
            final liste = snap.data!;
            if (liste.isEmpty) return const Note('Aucun échange en cours.');
            return Column(children: [
              for (final e in liste) ...[
                const SizedBox(height: 10),
                Bloc(enfants: [
                  Ligne(
                    '${membreLibelle(c, e['demandeurId'] as String, s.moi)} (place ${e['placeDemandeur']}) avec '
                    '${membreLibelle(c, e['cedantId'] as String, s.moi)} (place ${e['placeCedant']})',
                    valeur: switch (e['statut']) { 'propose' => 'proposé', 'signe' => 'signé', 'refuse' => 'refusé', 'expire' => 'expiré', final x => '$x' },
                    accent: e['statut'] == 'propose' && e['cedantId'] == s.moi,
                  ),
                  if (e['statut'] == 'propose' && e['cedantId'] == s.moi)
                    Row(children: [
                      Expanded(child: TextButton(onPressed: () => _faire(() => s.refuserEchange(c.id, e['id'] as String), 'Échange refusé.'), child: const Text('Refuser'))),
                      Expanded(child: TextButton(onPressed: () => _faire(() => s.accepterEchange(c.id, e), 'Échange signé.'), child: const Text('Accepter et signer'))),
                    ]),
                ]),
              ],
            ]);
          },
        ),
        if (maPlace != null) ...[
          Titre('Proposer un échange (ma place : $maPlace)'),
          Bloc(enfants: [
            for (final o in ordre.where((o) => o.membreId != s.moi))
              Ligne(
                'Place ${o.position}',
                valeur: 'proposer',
                onTap: () => _faire(
                  () => s.proposerEchange(cercleId: c.id, maPlace: maPlace, avecMembreId: o.membreId, saPlace: o.position),
                  'Proposition envoyée.',
                ),
              ),
          ]),
        ],
      ],
    );
  }
}

// --------------------------------------------- Assistant de l'organisateur

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, required this.cercle});

  final Cercle cercle;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantState();
}

class _AssistantState extends ConsumerState<AssistantScreen> {
  late Future<List<Map<String, dynamic>>> _journal = ref.read(espaceServiceProvider).journalAssistant(widget.cercle.id);
  String? _mode;

  void _recharger() => setState(() => _journal = ref.read(espaceServiceProvider).journalAssistant(widget.cercle.id));

  @override
  Widget build(BuildContext context) {
    final s = ref.read(espaceServiceProvider);
    String type(String t) => switch (t) {
          'rappel' || 'date_limite_proche' => 'Rappel avant échéance',
          'rappel_retard' || 'date_limite_depassee' => 'Relance d’un retard',
          'mise_en_demeure' => 'Mise en demeure',
          'defaut_constate' => 'Défaut constaté',
          _ => t.replaceAll('_', ' '),
        };
    return Ecran(
      titre: 'Assistant',
      enfants: [
        const Note(
          'L’assistant suit les échéances : rappels, relances, mises en demeure. En mode autonome il agit seul ; '
          'en mode manuel il te propose ses actions et tu décides.',
        ),
        const Titre('Mode'),
        Bloc(enfants: [
          for (final m in const ['autonome', 'manuel'])
            RadioListTile<String>(
              value: m,
              groupValue: _mode,
              title: Text(m == 'autonome' ? 'Autonome' : 'Manuel'),
              onChanged: (v) async {
                try {
                  await s.modeAssistant(widget.cercle.id, v!);
                  setState(() => _mode = v);
                  if (context.mounted) afficherMessage(context, 'Mode ${v == 'autonome' ? 'autonome' : 'manuel'} activé.');
                } catch (e) {
                  if (context.mounted) afficherErreur(context, e);
                }
              },
            ),
        ]),
        const Titre('Journal'),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _journal,
          builder: (context, snap) {
            if (snap.hasError) return Note(messageErreur(snap.error!));
            if (!snap.hasData) return const Squelette();
            if (snap.data!.isEmpty) return const Note('Aucune action pour l’instant.');
            return Bloc(enfants: [
              for (final a in snap.data!)
                Column(children: [
                  Ligne(
                    '${type(a['type'] as String)} · ${membreLibelle(widget.cercle, a['membreId'] as String, s.moi)}',
                    valeur: switch (a['issue']) { 'en_attente' => 'à décider', 'acceptee' => 'acceptée', 'refusee' => 'refusée', 'executee' => 'faite', 'hors_reglement' => 'hors règlement', final x => '$x' },
                    accent: a['issue'] == 'en_attente',
                  ),
                  if (a['issue'] == 'en_attente')
                    Row(children: [
                      Expanded(child: TextButton(onPressed: () => _decider(a['id'] as String, false), child: const Text('Refuser'))),
                      Expanded(child: TextButton(onPressed: () => _decider(a['id'] as String, true), child: const Text('Accepter'))),
                    ]),
                ]),
            ]);
          },
        ),
      ],
    );
  }

  Future<void> _decider(String id, bool accepte) async {
    try {
      await ref.read(espaceServiceProvider).deciderProposition(id, accepte: accepte);
      _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }
}

// ------------------------------------------------------- Dossier de preuve

class DossierPreuveScreen extends ConsumerWidget {
  const DossierPreuveScreen({super.key, required this.cercle, required this.membreId});

  final Cercle cercle;
  final String membreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(espaceServiceProvider).dossierDePreuve(cercle.id, membreId),
      builder: (context, snap) {
        if (snap.hasError) return Ecran(titre: 'Dossier de preuve', enfants: [Note(messageErreur(snap.error!))]);
        if (snap.connectionState != ConnectionState.done) {
          return const Ecran(titre: 'Dossier de preuve', enfants: [Squelette()]);
        }
        final d = snap.data;
        if (d == null) {
          return const Ecran(titre: 'Dossier de preuve', enfants: [Note('Aucun défaut constaté pour ce membre.')]);
        }
        final debiteur = d['debiteur'] as Map<String, dynamic>;
        return Ecran(
          titre: 'Dossier de preuve',
          enfants: [
            const Note(
              'Ce dossier rassemble ce que le membre a signé et ce qu’il n’a pas payé. '
              'Il peut servir devant une autorité ou un tribunal.',
            ),
            Bloc(enfants: [
              Ligne('Membre', valeur: debiteur['nom'] as String?),
              Ligne('Numéro', valeur: debiteur['numero'] as String?),
              Ligne('Niveau d’identité', valeur: '${debiteur['niveauIdentite']}'),
              Ligne('Dossier généré le', valeur: dateCourte(d['genereLe'] as String?)),
            ]),
            for (final e in d.entries.where((e) => !const ['debiteur', 'reglement', 'genereLe', 'cercleId'].contains(e.key)))
              if (e.value is List) ...[
                Titre(e.key),
                Bloc(enfants: [
                  for (final x in (e.value as List).take(20))
                    Ligne(x is Map ? x.entries.where((y) => y.value is! Map && y.value is! List).take(3).map((y) => '${y.key} : ${y.value}').join(' · ') : '$x'),
                ]),
              ],
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------- Mobile Money simulé

class PaiementSimuleScreen extends ConsumerStatefulWidget {
  const PaiementSimuleScreen({super.key, required this.cotisation});

  final Cotisation cotisation;

  @override
  ConsumerState<PaiementSimuleScreen> createState() => _PaiementSimuleState();
}

class _PaiementSimuleState extends ConsumerState<PaiementSimuleScreen> {
  String _operateur = 'orange_money';
  String _issue = 'reussi';
  bool _envoi = false;

  @override
  Widget build(BuildContext context) {
    return Ecran(
      titre: 'Mobile Money (démo)',
      enfants: [
        Note('Simulation d’un paiement de ${formatAmount(widget.cotisation.montant)} FCFA, sans argent réel. '
            'Un paiement réussi est déclaré automatiquement avec la référence de l’opérateur.'),
        const Titre('Opérateur'),
        Bloc(enfants: [
          RadioListTile(value: 'orange_money', groupValue: _operateur, onChanged: (v) => setState(() => _operateur = v!), title: const Text('Orange Money')),
          RadioListTile(value: 'mtn_momo', groupValue: _operateur, onChanged: (v) => setState(() => _operateur = v!), title: const Text('MTN Mobile Money')),
        ]),
        const Titre('Issue à simuler'),
        Bloc(enfants: [
          RadioListTile(value: 'reussi', groupValue: _issue, onChanged: (v) => setState(() => _issue = v!), title: const Text('Réussi')),
          RadioListTile(value: 'echoue', groupValue: _issue, onChanged: (v) => setState(() => _issue = v!), title: const Text('Échoué')),
          RadioListTile(value: 'en_retard', groupValue: _issue, onChanged: (v) => setState(() => _issue = v!), title: const Text('Réponse en retard')),
        ]),
      ],
      bas: AppButton(
        label: 'Payer (simulation)',
        isLoading: _envoi,
        onPressed: () async {
          setState(() => _envoi = true);
          try {
            final r = await ref.read(espaceServiceProvider).paiementSimule(widget.cotisation.id, operateur: _operateur, issue: _issue);
            ref.invalidate(mesCotisationsRefreshableProvider);
            ref.invalidate(mesCotisationsFiltreesProvider);
            if (!context.mounted) return;
            afficherMessage(context, switch (r['statut']) {
              'reussi' => 'Paiement réussi, référence ${r['referenceOperateur']}.',
              'echoue' => 'Paiement échoué : rien n’a été déclaré.',
              _ => 'L’opérateur n’a pas encore répondu.',
            });
            Navigator.pop(context, true);
          } catch (e) {
            afficherErreur(context, e);
          } finally {
            if (mounted) setState(() => _envoi = false);
          }
        },
      ),
    );
  }
}
