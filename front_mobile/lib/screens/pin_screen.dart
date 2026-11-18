import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import 'main_shell.dart';

/// Le PIN déverrouille l'app sur CE téléphone : il ne part jamais au serveur.
/// Seule son empreinte est gardée, dans le stockage sécurisé.
const _cleStockagePin = 'mondo_pin_empreinte';
const _stockage = FlutterSecureStorage();

String _empreinte(String pin) => sha256.convert(utf8.encode('mondo-pin:$pin')).toString();

Future<bool> pinDefini() async => (await _stockage.read(key: _cleStockagePin)) != null;

Future<void> effacerPin() => _stockage.delete(key: _cleStockagePin);

class PinScreen extends StatefulWidget {
  /// [verifier] : demander le PIN déjà choisi (à l'ouverture) au lieu d'en choisir un.
  const PinScreen({super.key, this.verifier = false});

  final bool verifier;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

  String _pin = '';

  void _onKey(String key) {
    if (key == 'back') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) _onComplete();
  }

  int _essais = 0;

  Future<void> _onComplete() async {
    if (widget.verifier) {
      final attendu = await _stockage.read(key: _cleStockagePin);
      if (attendu != _empreinte(_pin)) {
        _essais++;
        setState(() => _pin = '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code PIN incorrect ($_essais).')));
        }
        return;
      }
    } else {
      await _stockage.write(key: _cleStockagePin, value: _empreinte(_pin));
    }
    // Petit délai pour voir le 4e point se remplir
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, widget.verifier ? 'Ton code PIN' : 'Choisis ton code PIN'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ce code à 4 chiffres protège l'application sur ce téléphone.",
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.green : Colors.white,
                    border: Border.all(
                      color: filled ? AppColors.green : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: _keys.map((k) => _Key(value: k, onTap: _onKey)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onTap});

  final String value;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink(); // case vide

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(value),
        child: Center(
          child: value == 'back'
              ? const Icon(Icons.backspace_outlined, size: 24)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}