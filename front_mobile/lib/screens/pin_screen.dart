import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/logo_mondo.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';
import '../widgets/fond_motif.dart';

/// Le PIN déverrouille l'app sur CE téléphone : il ne part jamais au serveur.
/// Seule son empreinte est gardée, dans le stockage sécurisé.
const _cleStockagePin = 'mondo_pin_empreinte';

/// Codes faux à la suite, gardés même si l'application est fermée entre deux essais.
const _cleEchecsPin = 'mondo_pin_echecs';

/// Au-delà, la clé du téléphone est effacée : un téléphone volé ne se déverrouille pas en devinant le PIN.
const essaisPinMax = 5;
const _stockage = FlutterSecureStorage();

String _empreinte(String pin) => sha256.convert(utf8.encode('mondo-pin:$pin')).toString();

Future<bool> pinDefini() async => (await _stockage.read(key: _cleStockagePin)) != null;

Future<void> effacerPin() async {
  await _stockage.delete(key: _cleStockagePin);
  await _stockage.delete(key: _cleEchecsPin);
}

/// Choisir son PIN (deux fois, pour éviter une faute de frappe) ou le saisir à l'ouverture.
class PinScreen extends ConsumerStatefulWidget {
  /// [verifier] : demander le PIN déjà choisi (à l'ouverture) au lieu d'en choisir un.
  const PinScreen({super.key, this.verifier = false});

  final bool verifier;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _premier; // création : le premier code saisi, en attente de confirmation
  String? _erreur;

  String get _titre => widget.verifier
      ? 'Ton code PIN'
      : _premier == null
          ? 'Choisis ton code PIN'
          : 'Confirme ton code PIN';

  String get _sousTitre => widget.verifier
      ? 'Pour ouvrir MonDo sur ce téléphone.'
      : _premier == null
          ? '4 chiffres pour protéger l’application sur ce téléphone. Il ne quitte jamais le téléphone.'
          : 'Saisis-le une seconde fois.';

  void _touche(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      _erreur = null;
      if (k == 'effacer') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += k;
      }
    });
    if (_pin.length == 4) _complet();
  }

  Future<void> _complet() async {
    final saisi = _pin;
    if (widget.verifier) {
      final attendu = await _stockage.read(key: _cleStockagePin);
      if (attendu != _empreinte(saisi)) {
        final echecs = int.parse(await _stockage.read(key: _cleEchecsPin) ?? '0') + 1;
        await _stockage.write(key: _cleEchecsPin, value: '$echecs');
        HapticFeedback.heavyImpact();
        if (echecs >= essaisPinMax) return _effacerApresEchecs();
        final restants = essaisPinMax - echecs;
        setState(() {
          _pin = '';
          _erreur = restants == 1
              ? 'Code incorrect. Dernier essai : ensuite, ce téléphone oubliera ton compte.'
              : 'Code incorrect. Encore $restants essais.';
        });
        return;
      }
      await _stockage.delete(key: _cleEchecsPin);
    } else if (_premier == null) {
      setState(() {
        _premier = saisi;
        _pin = '';
      });
      return;
    } else if (_premier != saisi) {
      HapticFeedback.heavyImpact();
      setState(() {
        _premier = null;
        _pin = '';
        _erreur = 'Les deux codes diffèrent. Recommence.';
      });
      return;
    } else {
      await _stockage.write(key: _cleStockagePin, value: _empreinte(saisi));
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  /// Trop de codes faux : la clé est effacée de ce téléphone. Le compte n'est pas perdu, il se récupère
  /// avec le délai prévu (le titulaire peut s'y opposer depuis un autre téléphone).
  Future<void> _effacerApresEchecs() async {
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Trop de codes incorrects', style: TextStyle(color: AppColors.rouge)),
        content: const Text(
          'Par sécurité, ce téléphone a oublié ton compte. Ton compte et tes tontines ne sont pas perdus : '
          'choisis « J’ai déjà un compte » pour le récupérer.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris'))],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.barreSysteme, // icônes système lisibles, même sans barre d'app
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.verifier
          ? null
          : AppBar(
              leading: _premier == null
                  ? null
                  : BackButton(
                      onPressed: () => setState(() {
                        _premier = null;
                        _pin = '';
                      }),
                    ),
            ),
      body: FondMotif(child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: widget.verifier ? 48 : 8),
              LogoMonDo(taille: 44, couleur: AppColors.textDark),
              const SizedBox(height: 20),
              Text(_titre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _sousTitre,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 32),
              _Points(remplis: _pin.length, erreur: _erreur != null),
              SizedBox(
                height: 64,
                child: Center(
                  child: Text(
                    _erreur ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.rouge, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              _Clavier(onTouche: _touche, effacerActif: _pin.isNotEmpty),
              const SizedBox(height: 24),
            ],
          ),
        ),
      )),
    ),
    );
  }
}

class _Points extends StatelessWidget {
  const _Points({required this.remplis, required this.erreur});

  final int remplis;
  final bool erreur;

  @override
  Widget build(BuildContext context) {
    final couleur = erreur ? AppColors.rouge : AppColors.textDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < remplis ? couleur : Colors.transparent,
              border: Border.all(color: i < remplis ? couleur : (erreur ? AppColors.rouge : AppColors.textMuted), width: 1.5),
            ),
          ),
      ],
    );
  }
}

/// Clavier numérique sobre : chiffres sans fond, comme le clavier d'un téléphone.
class _Clavier extends StatelessWidget {
  const _Clavier({required this.onTouche, required this.effacerActif});

  final ValueChanged<String> onTouche;
  final bool effacerActif;

  @override
  Widget build(BuildContext context) {
    Widget touche(String k) {
      if (k.isEmpty) return const Expanded(child: SizedBox(height: 72));
      final effacer = k == 'effacer';
      return Expanded(
        child: SizedBox(
          height: 72,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: effacer && !effacerActif ? null : () => onTouche(k),
            child: Center(
              child: effacer
                  ? Icon(Icons.backspace_outlined,
                      size: 24, color: effacerActif ? AppColors.textDark : AppColors.border)
                  : Text(k, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400)),
            ),
          ),
        ),
      );
    }

    const lignes = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'effacer'],
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(children: [
        for (final l in lignes) Row(children: [for (final k in l) touche(k)]),
      ]),
    );
  }
}
