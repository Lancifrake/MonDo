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
import 'compte_demo_screen.dart';
import '../pin_screen.dart';
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

    // Verrouiller : la clé reste dans le téléphone, on revient au code PIN. Reprendre est immédiat.
    Future<void> verrouiller() async {
      final avecPin = await pinDefini();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinScreen(verifier: avecPin)),
        (_) => false,
      );
    }

    // Retirer le compte du téléphone (téléphone donné ou vendu) : la clé est effacée, et revenir
    // sur ce compte demande la récupération, avec son délai. C'est le seul cas où ce délai a du sens.
    Future<void> deconnecter() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Retirer ton compte de ce téléphone ?'),
          content: const Text(
            'À faire seulement si tu donnes ou vends ce téléphone. La clé de ce téléphone sera effacée : '
            'pour revenir sur ton compte, il faudra le récupérer, avec 48 à 72 h d’attente. '
            'Pour simplement fermer l’application, utilise plutôt « Verrouiller ».',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer le compte', style: TextStyle(color: AppColors.rouge))),
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
    }

    final verifiee = compte?.niveau == 2;
    final etatIdentite = verifiee
        ? 'Vérifiée'
        : switch (identite?['statut']) {
            'en_attente' => 'En examen',
            'refusee' => 'Refusée, à refaire',
            'validee' => 'Vérifiée',
            _ => 'À faire : pièce d’identité et selfie',
          };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Entete(nom: compte?.nom ?? '—', numero: compte?.numero ?? '', verifiee: verifiee),
          if (recup != null && recup['statut'] == 'en_attente')
            _Rangee(
              icone: Icons.warning_amber_rounded,
              titre: 'Quelqu’un tente de récupérer ton compte',
              detail: 'Sur un autre téléphone. Touche pour agir.',
              accent: true,
              onTap: () => ouvrir(RecuperationAlerteScreen(demande: recup)),
            ),
          if (profil.hasError)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Note(messageErreur(profil.error!))),
          const _Section('Confiance'),
          _Rangee(icone: Icons.speed_outlined, titre: 'Mon score', onTap: () => ouvrir(const ScoreScreen())),
          _Rangee(
            icone: Icons.verified_user_outlined,
            titre: 'Vérification d’identité',
            detail: etatIdentite,
            accent: !verifiee && identite == null,
            onTap: () => ouvrir(const IdentiteScreen()),
          ),
          _Rangee(icone: Icons.group_add_outlined, titre: 'Parrainages', onTap: () => ouvrir(const ParrainagesScreen())),
          _Rangee(
            icone: Icons.badge_outlined,
            titre: 'Mon identifiant',
            detail: moi.isEmpty ? '—' : '${moi.substring(0, 8)}… · touche pour copier',
            onTap: moi.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: moi));
                    afficherMessage(context, 'Identifiant copié : à donner à ton parrain.');
                  },
          ),
          const _Separation(),
          const _Section('Sécurité du compte'),
          _Rangee(
            icone: Icons.password_outlined,
            titre: 'Code secret de récupération',
            onTap: () => ouvrir(const CodeSecretScreen()),
          ),
          _Rangee(
            icone: Icons.contact_phone_outlined,
            titre: 'Contact de confiance',
            detail: contact == null
                ? 'Aucun pour l’instant'
                : contact['statut'] == 'accepte'
                    ? contact['nom'] as String
                    : 'En attente de sa réponse',
            accent: contact == null,
            onTap: () => ouvrir(ContactConfianceScreen(contact: contact)),
          ),
          const _Separation(),
          const _Section('Argent'),
          _Rangee(
            icone: Icons.payments_outlined,
            titre: 'Sommes dues',
            detail: sommesAFaire > 0 ? '$sommesAFaire à traiter' : 'Frais de place, remises, remboursements',
            accent: sommesAFaire > 0,
            onTap: () => ouvrir(const SommesDuesScreen()),
          ),
          // Raccourci de démonstration : seulement dans une version de démo (--dart-define=DEMO_COMPTES=true).
          if (comptesDemoActifs && compte?.niveau == 1) ...[
            const _Separation(),
            const _Section('Démonstration'),
            _Rangee(
              icone: Icons.science_outlined,
              titre: 'Passer au niveau 2 sans pièce',
              onTap: () async {
                try {
                  await ref.read(espaceServiceProvider).demoNiveau2();
                  await ref.read(authStateProvider.notifier).fetchProfil();
                  ref.invalidate(_profilProvider);
                  if (context.mounted) afficherMessage(context, 'Compte passé au niveau 2.');
                } catch (e) {
                  if (context.mounted) afficherErreur(context, e);
                }
              },
            ),
          ],
          const _Separation(),
          _Rangee(icone: Icons.lock_outline, titre: 'Verrouiller', onTap: verrouiller),
          _Rangee(
            icone: Icons.logout,
            titre: 'Retirer mon compte de ce téléphone',
            couleur: AppColors.rouge,
            onTap: deconnecter,
          ),
        ],
      ),
    );
  }
}

/// En-tête du profil : silhouette, nom, numéro et niveau d'identité.
class _Entete extends StatelessWidget {
  const _Entete({required this.nom, required this.numero, required this.verifiee});

  final String nom;
  final String numero;
  final bool verifiee;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(children: [
        // Comme la console : pas d'initiales, une silhouette neutre dans un rond clair.
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.person_outline, size: 30, color: AppColors.textMuted),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(numero, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(verifiee ? Icons.verified : Icons.info_outline,
                  size: 15, color: verifiee ? AppColors.green : AppColors.orange),
              const SizedBox(width: 4),
              Text(verifiee ? 'Identité vérifiée · niveau 2' : 'Niveau 1 · identité à vérifier',
                  style: TextStyle(fontSize: 13, color: verifiee ? AppColors.green : AppColors.orange)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        child: Text(texte, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      );
}

class _Separation extends StatelessWidget {
  const _Separation();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Divider(height: 1, thickness: 1, color: AppColors.border),
      );
}

/// Une ligne du profil, à la manière des réglages de WhatsApp : icône, intitulé, détail en dessous.
class _Rangee extends StatelessWidget {
  const _Rangee({
    required this.icone,
    required this.titre,
    this.detail,
    this.onTap,
    this.accent = false,
    this.couleur,
  });

  final IconData icone;
  final String titre;
  final String? detail;
  final VoidCallback? onTap;
  final bool accent; // orange : demande une action
  final Color? couleur;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
          child: Row(children: [
            Icon(icone, size: 24, color: couleur ?? (accent ? AppColors.orange : AppColors.textMuted)),
            const SizedBox(width: 26),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre, style: TextStyle(fontSize: 16, color: couleur ?? AppColors.textDark)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!,
                      style: TextStyle(fontSize: 13.5, color: accent ? AppColors.orange : AppColors.textMuted)),
                ],
              ]),
            ),
          ]),
        ),
      );
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

    List<Widget> rangees(List<Map<String, dynamic>> liste) => [
          for (var i = 0; i < liste.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, indent: 70, color: AppColors.border),
            _SommeRangee(
              somme: liste[i],
              jeDois: liste[i]['debiteurId'] == s.moi,
              declarer: () => declarer(liste[i]),
              confirmer: () => confirmer(liste[i]),
            ),
          ],
        ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sommes dues', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Note('Frais de place, part de MonDo, remises aux dernières places et remboursements après un départ.'),
          ),
          ...data.when(
            loading: () => [const LinearProgressIndicator()],
            error: (e, _) => [Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Note(messageErreur(e)))],
            data: (liste) {
              if (liste.isEmpty) {
                return [const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Note('Rien à payer ni à recevoir.'))];
              }
              final aPayer = liste.where((d) => d['debiteurId'] == s.moi).toList();
              final aRecevoir = liste.where((d) => d['debiteurId'] != s.moi).toList();
              return [
                if (aPayer.isNotEmpty) ...[const _Section('Je dois'), ...rangees(aPayer)],
                if (aPayer.isNotEmpty && aRecevoir.isNotEmpty) const _Separation(),
                if (aRecevoir.isNotEmpty) ...[const _Section('On me doit'), ...rangees(aRecevoir)],
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// Une somme due, à la manière du profil : icône selon la nature, intitulé et montant, échéance en dessous.
class _SommeRangee extends StatelessWidget {
  const _SommeRangee({required this.somme, required this.jeDois, required this.declarer, required this.confirmer});

  final Map<String, dynamic> somme;
  final bool jeDois;
  final VoidCallback declarer;
  final VoidCallback confirmer;

  @override
  Widget build(BuildContext context) {
    final statut = somme['statut'] as String?;
    final (IconData icone, String titre) = switch (somme['nature']) {
      'frais_mondo' => (Icons.confirmation_number_outlined, 'Part de MonDo'),
      'remise' => (Icons.redeem_outlined, 'Remise de place de fin'),
      'remboursement_depart' => (Icons.undo, 'Remboursement après un départ'),
      final n => (Icons.payments_outlined, '$n'),
    };
    final aFaire = (jeDois && statut == 'due') || (!jeDois && statut == 'declaree');
    final etat = switch (statut) {
      'due' => 'avant le ${dateCourte(somme['dateLimite'] as String?)}',
      'declaree' => jeDois ? 'déclarée, en attente de confirmation' : 'déclarée, à confirmer',
      'confirmee' => 'confirmée',
      'annulee' => 'annulée',
      final x => '$x',
    };
    final montant = '${jeDois ? '−' : '+'}${formatAmount(somme['montant'] as int)} FCFA';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icone, size: 24, color: aFaire ? AppColors.orange : AppColors.textMuted),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(titre, style: const TextStyle(fontSize: 16))),
              Text(
                montant,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: jeDois ? AppColors.textDark : AppColors.green,
                ),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              'Tour ${somme['tour'] ?? '—'} · $etat',
              style: TextStyle(fontSize: 13.5, color: aFaire ? AppColors.orange : AppColors.textMuted),
            ),
            if (jeDois && statut == 'due')
              _Action('J’ai payé : déclarer', declarer)
            else if (!jeDois && statut == 'declaree')
              _Action('Confirmer la réception', confirmer),
          ]),
        ),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.texte, this.onTap);

  final String texte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
          onPressed: onTap,
          child: Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
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
const accentAction = AppColors.orange;
