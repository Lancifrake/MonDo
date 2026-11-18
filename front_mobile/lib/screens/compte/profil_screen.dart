import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';
import '../score/score_screen.dart';
import '../welcome_screen.dart';

/// Ce qu'il faut afficher sur le profil, lu en une fois.
final _profilProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final s = ref.watch(espaceServiceProvider);
  final r = await Future.wait<Object?>([
    s.contactDeConfiance(),
    s.monIdentite(),
    s.recuperationEnCours(),
    s.sommesDues(),
  ]);
  return {'contact': r[0], 'identite': r[1], 'recuperation': r[2], 'sommes': r[3]};
});

/// Onglet Profil : mon compte, ma sécurité, mes parrainages et sommes dues.
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compte = ref.watch(authStateProvider).compte;
    final profil = ref.watch(_profilProvider);
    final moi = ref.read(espaceServiceProvider).moi;

    Future<void> ouvrir(Widget page) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      ref.invalidate(_profilProvider);
    }

    final p = profil.valueOrNull ?? const {};
    final contact = p['contact'] as Map<String, dynamic>?;
    final identite = p['identite'] as Map<String, dynamic>?;
    final recup = p['recuperation'] as Map<String, dynamic>?;
    final sommes = (p['sommes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final sommesAFaire = sommes.where((s) =>
        (s['debiteurId'] == moi && s['statut'] == 'due') || (s['creancierId'] == moi && s['statut'] == 'declaree')).length;

    return Ecran(
      titre: 'Profil',
      enfants: [
        if (recup != null && recup['statut'] == 'en_attente')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Bloc(enfants: [
              Ligne(
                'Quelqu’un tente de récupérer ton compte sur un autre téléphone',
                valeur: 'Agir',
                accent: true,
                onTap: () => ouvrir(RecuperationAlerteScreen(demande: recup)),
              ),
            ]),
          ),
        if (profil.hasError) Note(messageErreur(profil.error!)),
        Bloc(enfants: [
          Ligne('Nom', valeur: compte?.nom ?? '—'),
          Ligne('Numéro', valeur: compte?.numero ?? '—'),
          Ligne('Niveau d’identité', valeur: compte == null ? '—' : '${compte.niveau}'),
          Ligne(
            'Mon identifiant',
            valeur: moi.isEmpty ? '—' : '${moi.substring(0, 8)}…  copier',
            onTap: moi.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: moi));
                    afficherMessage(context, 'Identifiant copié : à donner à ton parrain.');
                  },
          ),
        ]),
        const Titre('Confiance'),
        Bloc(enfants: [
          Ligne('Mon score', onTap: () => ouvrir(const ScoreScreen())),
          Ligne(
            'Vérification d’identité',
            valeur: compte?.niveau == 2
                ? 'vérifiée'
                : switch (identite?['statut']) {
                    'en_attente' => 'en examen',
                    'refusee' => 'refusée',
                    'validee' => 'vérifiée',
                    _ => 'à faire',
                  },
            accent: compte?.niveau != 2 && identite == null,
            onTap: () => ouvrir(const IdentiteScreen()),
          ),
          Ligne('Parrainages', onTap: () => ouvrir(const ParrainagesScreen())),
        ]),
        const Titre('Sécurité du compte'),
        Bloc(enfants: [
          Ligne('Code secret de récupération', onTap: () => ouvrir(const CodeSecretScreen())),
          Ligne(
            'Contact de confiance',
            valeur: contact == null
                ? 'aucun'
                : contact['statut'] == 'accepte'
                    ? contact['nom'] as String
                    : 'en attente',
            accent: contact == null,
            onTap: () => ouvrir(ContactConfianceScreen(contact: contact)),
          ),
        ]),
        const Titre('Argent'),
        Bloc(enfants: [
          Ligne(
            'Sommes dues (frais, remises)',
            valeur: sommesAFaire > 0 ? '$sommesAFaire à traiter' : null,
            accent: sommesAFaire > 0,
            onTap: () => ouvrir(const SommesDuesScreen()),
          ),
        ]),
        const SizedBox(height: 28),
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Se déconnecter ?'),
                content: const Text(
                  'La clé de ce téléphone sera effacée. Sans code secret ni contact de confiance, '
                  'tu ne pourras plus accéder à ce compte.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Effacer la clé')),
                ],
              ),
            );
            if (ok != true) return;
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            }
          },
          child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFB45309))),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Code secret

class CodeSecretScreen extends ConsumerStatefulWidget {
  const CodeSecretScreen({super.key});

  @override
  ConsumerState<CodeSecretScreen> createState() => _CodeSecretState();
}

class _CodeSecretState extends ConsumerState<CodeSecretScreen> {
  final _code = TextEditingController();
  final _confirmation = TextEditingController();
  bool _envoi = false;

  @override
  Widget build(BuildContext context) {
    return Ecran(
      titre: 'Code secret',
      enfants: [
        const Note(
          'Ce code de 4 à 8 chiffres te permet de récupérer ton compte depuis un nouveau téléphone. '
          'Il n’est pas affiché ensuite : note-le dans un endroit sûr. Le définir de nouveau remplace l’ancien.',
        ),
        const SizedBox(height: 12),
        Champ(controleur: _code, libelle: 'Code secret', clavier: TextInputType.number),
        Champ(controleur: _confirmation, libelle: 'Confirmer le code', clavier: TextInputType.number),
      ],
      bas: AppButton(
        label: 'Enregistrer',
        isLoading: _envoi,
        onPressed: () async {
          if (!RegExp(r'^\d{4,8}$').hasMatch(_code.text)) {
            return afficherMessage(context, 'Le code fait 4 à 8 chiffres.');
          }
          if (_code.text != _confirmation.text) return afficherMessage(context, 'Les deux codes diffèrent.');
          setState(() => _envoi = true);
          try {
            await ref.read(espaceServiceProvider).definirCodeSecret(_code.text);
            if (!context.mounted) return;
            afficherMessage(context, 'Code secret enregistré.');
            Navigator.pop(context);
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

// ---------------------------------------------------- Contact de confiance

class ContactConfianceScreen extends ConsumerStatefulWidget {
  const ContactConfianceScreen({super.key, this.contact});

  final Map<String, dynamic>? contact;

  @override
  ConsumerState<ContactConfianceScreen> createState() => _ContactState();
}

class _ContactState extends ConsumerState<ContactConfianceScreen> {
  late Map<String, dynamic>? _contact = widget.contact;
  final _nom = TextEditingController();
  final _numero = TextEditingController();
  final _code = TextEditingController();
  bool _envoi = false;

  Future<void> _faire(Future<Map<String, dynamic>> Function() action, String ok) async {
    setState(() => _envoi = true);
    try {
      final r = await action();
      setState(() => _contact = r);
      if (mounted) afficherMessage(context, ok);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.read(espaceServiceProvider);
    final c = _contact;
    final enAttente = c != null && c['statut'] == 'en_attente';
    return Ecran(
      titre: 'Contact de confiance',
      enfants: [
        const Note(
          'Une personne proche confirme par SMS qu’elle accepte d’être ton contact. '
          'Si tu changes de téléphone, elle pourra confirmer que c’est bien toi, sans pièce d’identité.',
        ),
        if (c != null) ...[
          const Titre('Contact actuel'),
          Bloc(enfants: [
            Ligne('Nom', valeur: c['nom'] as String?),
            Ligne('Numéro', valeur: c['numero'] as String?),
            Ligne('Statut', valeur: switch (c['statut']) {
              'accepte' => 'a accepté le ${dateCourte(c['consentementLe'] as String?)}',
              'en_attente' => 'attend son accord jusqu’au ${dateCourte(c['expireLe'] as String?)}',
              final autre => '$autre',
            }, accent: enAttente),
          ]),
        ],
        if (enAttente) ...[
          const Titre('Son accord'),
          const Note('Ton contact a reçu un code à 6 chiffres. Demande-le-lui et saisis-le ici.'),
          Champ(controleur: _code, libelle: 'Code reçu par ton contact', clavier: TextInputType.number),
          AppButton(
            label: 'Valider son accord',
            isLoading: _envoi,
            onPressed: () => _faire(() => s.accordDuContact(_code.text.trim()), 'Contact de confiance confirmé.'),
          ),
        ],
        Titre(c == null ? 'Désigner un contact' : 'Changer de contact'),
        Champ(controleur: _nom, libelle: 'Son nom'),
        Champ(controleur: _numero, libelle: 'Son numéro', clavier: TextInputType.phone, prefixe: '+237 '),
        AppButton(
          label: 'Lui envoyer la demande par SMS',
          isLoading: _envoi && !enAttente,
          onPressed: () => _faire(
            () => s.designerContact(nom: _nom.text.trim(), numero: '+237${_numero.text.replaceAll(' ', '')}'),
            'Demande envoyée à ton contact.',
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------- Vérification d'identité

class IdentiteScreen extends ConsumerStatefulWidget {
  const IdentiteScreen({super.key});

  @override
  ConsumerState<IdentiteScreen> createState() => _IdentiteState();
}

class _IdentiteState extends ConsumerState<IdentiteScreen> {
  late final Future<List<Object?>> _chargement = Future.wait([
    ref.read(espaceServiceProvider).monIdentite(),
    ref.read(espaceServiceProvider).consentementIdentite(),
  ]);
  String _type = 'cni';
  final Map<String, String> _images = {}; // recto, verso, selfie -> base64
  bool _accepte = false;
  bool _envoi = false;

  Future<void> _photo(String nature) async {
    final image = await ImagePicker().pickImage(
      source: nature == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: nature == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1600,
      imageQuality: 80, // JPEG compressé : le serveur refuse au-delà de 2 Mo
    );
    if (image == null) return;
    final octets = await image.readAsBytes();
    if (octets.length > 2 * 1024 * 1024) {
      if (mounted) afficherMessage(context, 'Image trop lourde (2 Mo au plus).');
      return;
    }
    setState(() => _images[nature] = base64Encode(octets));
  }

  @override
  Widget build(BuildContext context) {
    final niveau = ref.watch(authStateProvider).compte?.niveau ?? 1;
    return FutureBuilder<List<Object?>>(
      future: _chargement,
      builder: (context, snap) {
        if (snap.hasError) return Ecran(titre: 'Identité', enfants: [Note(messageErreur(snap.error!))]);
        if (!snap.hasData) return const Ecran(titre: 'Identité', enfants: [LinearProgressIndicator()]);
        final dossier = snap.data![0] as Map<String, dynamic>?;
        final consentement = snap.data![1] as Map<String, dynamic>;
        if (niveau == 2 || dossier?['statut'] == 'validee') {
          return const Ecran(titre: 'Identité', enfants: [
            Note('Ton identité est vérifiée : tu es au niveau 2 et peux rejoindre des tontines ouvertes.'),
          ]);
        }
        if (dossier?['statut'] == 'en_attente') {
          return Ecran(titre: 'Identité', enfants: [
            Note('Ton dossier, déposé le ${dateCourte(dossier!['deposeeLe'] as String?)}, est en examen par un administrateur MonDo.'),
          ]);
        }
        final complet = _images.length == 3 && _accepte;
        return Ecran(
          titre: 'Vérifier mon identité',
          enfants: [
            if (dossier?['statut'] == 'refusee')
              Note('Dossier précédent refusé : ${dossier!['motifDecision'] ?? 'sans motif'}. Tu peux en déposer un nouveau.'),
            const Note('Le niveau 2 permet de rejoindre des tontines ouvertes à des inconnus.'),
            const Titre('Pièce'),
            Bloc(enfants: [
              RadioListTile<String>(value: 'cni', groupValue: _type, onChanged: (v) => setState(() => _type = v!), title: const Text('Carte nationale d’identité')),
              RadioListTile<String>(value: 'passeport', groupValue: _type, onChanged: (v) => setState(() => _type = v!), title: const Text('Passeport')),
            ]),
            const Titre('Photos'),
            Bloc(enfants: [
              for (final n in const ['recto', 'verso', 'selfie'])
                Ligne(
                  switch (n) { 'recto' => 'Recto de la pièce', 'verso' => 'Verso de la pièce', _ => 'Selfie' },
                  valeur: _images.containsKey(n) ? 'ajoutée' : 'ajouter',
                  accent: !_images.containsKey(n),
                  onTap: () => _photo(n),
                ),
            ]),
            const Titre('Consentement'),
            Note(consentement['texte'] as String),
            CheckboxListTile(
              value: _accepte,
              onChanged: (v) => setState(() => _accepte = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('J’accepte'),
            ),
          ],
          bas: AppButton(
            label: 'Envoyer mon dossier',
            isLoading: _envoi,
            onPressed: !complet
                ? null
                : () async {
                    setState(() => _envoi = true);
                    try {
                      await ref.read(espaceServiceProvider).deposerIdentite(
                            typePiece: _type,
                            versionConsentement: consentement['version'] as String,
                            recto: _images['recto']!,
                            verso: _images['verso']!,
                            selfie: _images['selfie']!,
                          );
                      if (!context.mounted) return;
                      afficherMessage(context, 'Dossier envoyé. Un administrateur va l’examiner.');
                      Navigator.pop(context);
                    } catch (e) {
                      afficherErreur(context, e);
                    } finally {
                      if (mounted) setState(() => _envoi = false);
                    }
                  },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------- Parrainages

final _parrainagesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(espaceServiceProvider).parrainages());

class ParrainagesScreen extends ConsumerStatefulWidget {
  const ParrainagesScreen({super.key});

  @override
  ConsumerState<ParrainagesScreen> createState() => _ParrainagesState();
}

class _ParrainagesState extends ConsumerState<ParrainagesScreen> {
  final _filleul = TextEditingController();

  Future<void> _faire(Future<Object?> Function() action, String ok) async {
    try {
      await action();
      ref.invalidate(_parrainagesProvider);
      if (mounted) afficherMessage(context, ok);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.read(espaceServiceProvider);
    final data = ref.watch(_parrainagesProvider);
    String etat(Map p) => switch (p['statut']) { 'propose' => 'proposé', 'accepte' => 'accepté', 'refuse' => 'refusé', final x => '$x' };
    return Ecran(
      titre: 'Parrainages',
      enfants: [
        const Note(
          'Un parrain au bon score se porte garant d’un nouveau membre : le filleul peut entrer dans une tontine '
          'sous le seuil de score si l’organisateur l’accepte et que son parrain en est membre.',
        ),
        ...data.when(
          loading: () => [const LinearProgressIndicator()],
          error: (e, _) => [Note(messageErreur(e))],
          data: (d) {
            final recus = (d['commeFilleul'] as List).cast<Map<String, dynamic>>();
            final donnes = (d['commeParrain'] as List).cast<Map<String, dynamic>>();
            return [
              const Titre('On me parraine'),
              if (recus.isEmpty) const Note('Aucune proposition.'),
              for (final p in recus)
                Bloc(enfants: [
                  Ligne('Proposé le ${dateCourte(p['proposeLe'] as String?)}', valeur: etat(p)),
                  if (p['statut'] == 'propose')
                    Row(children: [
                      Expanded(child: TextButton(onPressed: () => _faire(() => s.repondreParrainage(p['id'] as String, accepte: false), 'Parrainage refusé.'), child: const Text('Refuser'))),
                      Expanded(child: TextButton(onPressed: () => _faire(() => s.repondreParrainage(p['id'] as String, accepte: true), 'Parrainage accepté.'), child: const Text('Accepter'))),
                    ]),
                ]),
              const Titre('Je parraine'),
              if (donnes.isEmpty) const Note('Personne pour l’instant.'),
              for (final p in donnes)
                Bloc(enfants: [Ligne('Filleul ${(p['filleulId'] as String).substring(0, 8)}…', valeur: etat(p))]),
            ];
          },
        ),
        const Titre('Parrainer quelqu’un'),
        const Note('Demande-lui son identifiant (Profil, « Mon identifiant »). Il faut un score d’au moins 30.'),
        Champ(controleur: _filleul, libelle: 'Identifiant du filleul'),
        AppButton(
          label: 'Proposer le parrainage',
          onPressed: () => _faire(() => s.proposerParrainage(_filleul.text.trim()), 'Proposition envoyée.'),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- Sommes dues

final _sommesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(espaceServiceProvider).sommesDues());

class SommesDuesScreen extends ConsumerWidget {
  const SommesDuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.read(espaceServiceProvider);
    final data = ref.watch(_sommesProvider);
    String nature(String n) => switch (n) {
          'frais_mondo' => 'Part de MonDo (frais de place)',
          'remise' => 'Remise de place de fin',
          'remboursement_depart' => 'Remboursement après un départ',
          _ => n,
        };

    Future<void> declarer(Map<String, dynamic> d) async {
      final ctrl = TextEditingController();
      final ref0 = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${formatAmount(d['montant'] as int)} FCFA payés'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Référence Mobile Money')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Déclarer')),
          ],
        ),
      );
      if (ref0 == null || ref0.trim().isEmpty) return;
      try {
        await s.declarerSommeDue(d['id'] as String, ref0);
        ref.invalidate(_sommesProvider);
        if (context.mounted) afficherMessage(context, 'Paiement déclaré.');
      } catch (e) {
        if (context.mounted) afficherErreur(context, e);
      }
    }

    Future<void> confirmer(Map<String, dynamic> d) async {
      try {
        await s.confirmerSommeDue(d['id'] as String);
        ref.invalidate(_sommesProvider);
        if (context.mounted) afficherMessage(context, 'Réception confirmée.');
      } catch (e) {
        if (context.mounted) afficherErreur(context, e);
      }
    }

    return Ecran(
      titre: 'Sommes dues',
      enfants: [
        const Note('Frais de place, part de MonDo, remises aux dernières places et remboursements après un départ.'),
        ...data.when(
          loading: () => [const LinearProgressIndicator()],
          error: (e, _) => [Note(messageErreur(e))],
          data: (liste) => liste.isEmpty
              ? [const Note('Rien à payer ni à recevoir.')]
              : [
                  for (final d in liste) ...[
                    const SizedBox(height: 10),
                    Bloc(enfants: [
                      Ligne(nature(d['nature'] as String), valeur: '${formatAmount(d['montant'] as int)} FCFA'),
                      Ligne(
                        d['debiteurId'] == s.moi ? 'Je dois · tour ${d['tour'] ?? '—'}' : 'On me doit · tour ${d['tour'] ?? '—'}',
                        valeur: switch (d['statut']) { 'due' => 'avant le ${dateCourte(d['dateLimite'] as String?)}', 'declaree' => 'déclarée', 'confirmee' => 'confirmée', final x => '$x' },
                        accent: d['statut'] != 'confirmee',
                      ),
                      if (d['debiteurId'] == s.moi && d['statut'] == 'due')
                        TextButton(onPressed: () => declarer(d), child: const Text('J’ai payé : déclarer')),
                      if (d['creancierId'] == s.moi && d['statut'] == 'declaree')
                        TextButton(onPressed: () => confirmer(d), child: const Text('Confirmer la réception')),
                    ]),
                  ],
                ],
        ),
      ],
    );
  }
}

// ----------------------------------------------- Alerte de récupération

class RecuperationAlerteScreen extends ConsumerStatefulWidget {
  const RecuperationAlerteScreen({super.key, required this.demande});

  final Map<String, dynamic> demande;

  @override
  ConsumerState<RecuperationAlerteScreen> createState() => _RecuperationAlerteState();
}

class _RecuperationAlerteState extends ConsumerState<RecuperationAlerteScreen> {
  bool _envoi = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    return Ecran(
      titre: 'Récupération de ton compte',
      enfants: [
        Note(
          'Le ${dateCourte(d['demandeeLe'] as String?)}, quelqu’un a demandé à récupérer ton compte depuis un autre téléphone. '
          'Sans réaction de ta part, la récupération aboutira le ${dateCourte(d['finDelaiLe'] as String?)}.',
        ),
        const Note(
          'Si ce n’est pas toi, oppose-toi : ton compte sera bloqué le temps qu’un administrateur MonDo vérifie, '
          'et tes échéances suspendues.',
        ),
      ],
      bas: AppButton(
        label: 'Ce n’est pas moi : m’opposer',
        isLoading: _envoi,
        onPressed: () async {
          setState(() => _envoi = true);
          try {
            await ref.read(espaceServiceProvider).sOpposerALaRecuperation();
            if (!context.mounted) return;
            afficherMessage(context, 'Opposition enregistrée. Un administrateur va trancher.');
            Navigator.pop(context);
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

// Couleur d'accent partagée avec les autres écrans
const accentAction = AppColors.amberText;
