import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../services/recuperation_locale.dart';
import '../pin_screen.dart';
import '../../services/crypto_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';
import '../../theme/app_colors.dart';

/// Version du consentement à l'identité en vigueur côté serveur. Le nouveau téléphone
/// n'est pas encore connecté et ne peut pas la lire (la route est réservée au titulaire).
const _versionConsentement = '2026-11-11';

/// Récupérer son compte depuis un nouveau téléphone (POST /comptes/recuperation).
///
/// Le nouveau téléphone crée sa clé et prouve qu'il la détient. Avec un contact de confiance
/// ou le code secret, la demande aboutit à la fin du délai, sauf opposition de l'ancien téléphone.
/// Sans contact, il faut déposer pièce d'identité et selfie, examinés par un administrateur.
class RecuperationScreen extends ConsumerStatefulWidget {
  /// [reprise] : une demande déjà faite depuis ce téléphone (app rouverte ou réinstallée).
  const RecuperationScreen({super.key, this.reprise});

  final RecuperationLocale? reprise;

  @override
  ConsumerState<RecuperationScreen> createState() => _RecuperationState();
}

class _RecuperationState extends ConsumerState<RecuperationScreen> {
  final _numero = TextEditingController();
  final _code = TextEditingController();
  final _secret = TextEditingController();
  bool _codeDemande = false;
  bool _envoi = false;
  CryptoService? _cle;
  Map<String, dynamic>? _demande;
  final Map<String, String> _pieces = {};
  final _identifiant = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.reprise;
    if (r != null) {
      _cle = r.cle;
      _demande = {'id': r.recuperationId, 'finDelaiLe': r.finDelaiLe, 'piecesRequises': r.piecesRequises, 'statut': 'en_attente'};
      _numero.text = r.numero.replaceFirst('+237', '');
    }
  }

  String get _numeroComplet => '+237${_numero.text.replaceAll(' ', '')}';

  Future<void> _envoyer(Future<void> Function() action) async {
    setState(() => _envoi = true);
    try {
      await action();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _demanderCode() => _envoyer(() async {
        await ref.read(apiClientProvider).post<dynamic>('/comptes/otp', data: {'numero': _numeroComplet}, fromJson: (j) => j);
        setState(() => _codeDemande = true);
      });

  Future<void> _demanderRecuperation() => _envoyer(() async {
        final cle = _cle ??= await CryptoService.generateKeyPair();
        final r = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
              '/comptes/recuperation',
              data: {
                'numero': _numeroComplet,
                'clePublique': cle.publicJwk,
                'preuve': cle.signRecuperation(numero: _numeroComplet),
                'codeOtp': _code.text.trim(),
                if (_secret.text.trim().isNotEmpty) 'codeSecret': _secret.text.trim(),
              },
              fromJson: (j) => j as Map<String, dynamic>,
            );
        await RecuperationLocale(
          numero: _numeroComplet,
          recuperationId: r['id'] as String,
          cle: cle,
          finDelaiLe: r['finDelaiLe'] as String,
          piecesRequises: r['piecesRequises'] == true,
        ).enregistrer();
        setState(() => _demande = r);
      });

  /// Ouvre le compte récupéré : le serveur ne donne pas l'identifiant du compte au nouveau téléphone,
  /// il faut le saisir (Profil, « Mon identifiant », sur l'ancien téléphone, ou l'administrateur).
  Future<void> _ouvrirCompte() => _envoyer(() async {
        final id = _identifiant.text.trim();
        if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
          return afficherMessage(context, 'L’identifiant est un code de 36 caractères (xxxxxxxx-xxxx-…).');
        }
        final cle = _cle!;
        final auth = ref.read(authStateProvider.notifier);
        await auth.setCurrentSession(membreId: id, cryptoService: cle);
        try {
          await auth.fetchProfil(); // requête signée : refusée tant que la récupération n'est pas aboutie
        } catch (e) {
          ref.read(apiClientProvider).reset();
          rethrow;
        }
        await ref.read(localStorageProvider).saveSession(membreId: id, phoneNumber: _numeroComplet, cryptoService: cle);
        await RecuperationLocale.effacer();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PinScreen()), (_) => false);
      });

  Future<void> _abandonner() async {
    await RecuperationLocale.effacer();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _photo(String nature) async {
    final image = await ImagePicker().pickImage(
      source: nature == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (image == null) return;
    _pieces[nature] = base64Encode(await image.readAsBytes());
    setState(() {});
  }

  Future<void> _deposerPieces() => _envoyer(() async {
        final cle = _cle!;
        final id = _demande!['id'] as String;
        final horodatage = CryptoService.horodatage();
        await ref.read(apiClientProvider).post<dynamic>(
              '/comptes/recuperation/$id/pieces',
              data: {
                'typePiece': 'cni',
                'consentement': true,
                'versionConsentement': _versionConsentement,
                'recto': _pieces['recto'],
                'verso': _pieces['verso'],
                'selfie': _pieces['selfie'],
                'horodatage': horodatage,
                'preuve': cle.signMessage(CryptoService.canonique({
                  'objet': 'pieces_recuperation',
                  'recuperationId': id,
                  'horodatage': horodatage,
                })),
              },
              fromJson: (j) => j,
            );
        if (mounted) afficherMessage(context, 'Pièces envoyées. Un administrateur va les examiner.');
        setState(() => _pieces.clear());
      });

  @override
  Widget build(BuildContext context) {
    final d = _demande;
    if (d != null) {
      return Ecran(
        titre: 'Récupération demandée',
        enfants: [
          Bloc(enfants: [
            Ligne('Demandée le', valeur: dateCourte(d['demandeeLe'] as String?)),
            Ligne('Aboutit le', valeur: dateCourte(d['finDelaiLe'] as String?)),
            Ligne('Contact de confiance', valeur: d['avecContact'] == true ? 'oui' : 'non'),
            Ligne('Statut', valeur: d['statut'] == 'en_attente' ? 'en attente' : '${d['statut']}'),
          ]),
          const Note(
            'Ton ancien téléphone est prévenu et peut s’opposer pendant ce délai. '
            'Garde cette application ouverte sur ce téléphone : sa clé est celle qui remplacera l’ancienne.',
          ),
          const Titre('Quand c’est abouti'),
          const Note(
            'Quand la date ci-dessus est passée (et, sans contact de confiance, que ton dossier est validé), '
            'saisis l’identifiant de ton compte pour l’ouvrir sur ce téléphone. Tu le trouves dans Profil, '
            '« Mon identifiant », sur l’ancien téléphone, ou auprès de l’administrateur.',
          ),
          Champ(controleur: _identifiant, libelle: 'Identifiant du compte'),
          AppButton(label: 'Ouvrir mon compte', isLoading: _envoi, onPressed: _ouvrirCompte),
          TextButton(
            onPressed: _abandonner,
            child: Text('Abandonner cette demande sur ce téléphone', style: TextStyle(color: AppColors.rouge)),
          ),
          if (d['piecesRequises'] == true) ...[
            const Titre('Pièces à déposer'),
            const Note('Sans contact de confiance, un administrateur vérifie ta carte d’identité et ton selfie.'),
            Bloc(enfants: [
              for (final n in const ['recto', 'verso', 'selfie'])
                Ligne(
                  switch (n) { 'recto' => 'Recto de la CNI', 'verso' => 'Verso de la CNI', _ => 'Selfie' },
                  valeur: _pieces.containsKey(n) ? 'ajoutée' : 'ajouter',
                  accent: !_pieces.containsKey(n),
                  onTap: () => _photo(n),
                ),
            ]),
            const SizedBox(height: 12),
            AppButton(
              label: 'Envoyer les pièces',
              isLoading: _envoi,
              onPressed: _pieces.length == 3 ? _deposerPieces : null,
            ),
          ],
        ],
      );
    }
    return Ecran(
      titre: 'Récupérer mon compte',
      enfants: [
        const Note(
          'Tu as changé de téléphone ? Ce téléphone va créer une nouvelle clé. '
          'Ton contact de confiance ou ton code secret confirment que c’est bien toi.',
        ),
        Champ(controleur: _numero, libelle: 'Mon numéro', clavier: TextInputType.phone, prefixe: '+237 '),
        if (!_codeDemande)
          AppButton(label: 'Recevoir le code par SMS', isLoading: _envoi, onPressed: _demanderCode)
        else ...[
          Champ(controleur: _code, libelle: 'Code reçu par SMS', clavier: TextInputType.number),
          Champ(controleur: _secret, libelle: 'Code secret (si tu en as défini un)', clavier: TextInputType.number),
          AppButton(label: 'Demander la récupération', isLoading: _envoi, onPressed: _demanderRecuperation),
        ],
      ],
    );
  }
}
