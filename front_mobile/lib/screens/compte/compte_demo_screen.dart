import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../services/crypto_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sobre.dart';
import '../pin_screen.dart';

/// Compte de démonstration à reprendre : uniquement dans les versions de TEST
/// (`--dart-define=DEMO_COMPTES=true`). Un compte est lié à la clé de SON appareil ; pour
/// qu'un testeur reprenne un compte déjà peuplé, on lui donne un « code de compte » qui contient
/// cette clé. À ne JAMAIS activer pour de vrais comptes : qui a ce code EST ce compte.
const comptesDemoActifs = bool.fromEnvironment('DEMO_COMPTES');

class CompteDemoScreen extends ConsumerStatefulWidget {
  const CompteDemoScreen({super.key});

  @override
  ConsumerState<CompteDemoScreen> createState() => _CompteDemoState();
}

class _CompteDemoState extends ConsumerState<CompteDemoScreen> {
  final _code = TextEditingController();
  bool _envoi = false;

  Future<void> _ouvrir() async {
    setState(() => _envoi = true);
    try {
      final brut = _code.text.trim().replaceAll(RegExp(r'\s+'), '');
      if (!brut.startsWith('mondo-demo:')) throw const FormatException('Ce code ne vient pas de MonDo.');
      final d = jsonDecode(utf8.decode(base64.decode(brut.substring('mondo-demo:'.length)))) as Map<String, dynamic>;
      final cle = CryptoService.fromPrivateHex(d['cle'] as String);
      final auth = ref.read(authStateProvider.notifier);
      await auth.setCurrentSession(membreId: d['id'] as String, cryptoService: cle);
      await auth.fetchProfil(); // requête signée : échoue si la clé n'est pas la bonne
      await ref.read(localStorageProvider).saveSession(
            membreId: d['id'] as String,
            phoneNumber: d['numero'] as String,
            cryptoService: cle,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PinScreen()),
        (_) => false,
      );
    } on FormatException catch (e) {
      if (mounted) afficherMessage(context, e.message.isEmpty ? 'Code illisible.' : e.message);
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Ecran(
      titre: 'Compte de démonstration',
      enfants: [
        const Note(
          'Version de test : colle ici le code de compte qu’on t’a donné. Tu reprends alors un compte déjà '
          'peuplé (tontines, cotisations, historique), puis tu choisis ton PIN. Ce code vaut mot de passe : ne le partage pas.',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _code,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'mondo-demo:…'),
        ),
        TextButton(
          onPressed: () async {
            final presse = await Clipboard.getData(Clipboard.kTextPlain);
            if (presse?.text != null) setState(() => _code.text = presse!.text!);
          },
          child: const Text('Coller depuis le presse-papiers'),
        ),
      ],
      bas: AppButton(label: 'Ouvrir ce compte', isLoading: _envoi, onPressed: _ouvrir),
    );
  }
}
