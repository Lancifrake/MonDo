import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/bottom_bar.dart';
import 'pin_screen.dart';
import 'unlock_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, this.isLogin = false});

  final String phone;
  final bool isLogin; // true = j'ai déjà un compte (connexion)

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeCtrl = TextEditingController();
  Timer? _timer;
  int _seconds = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    // Connexion : on saisit son PIN. Inscription : on en choisit un.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.isLogin ? const UnlockScreen() : const PinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Code de vérification'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saisis le code envoyé au +237 ${widget.phone}.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Aperçu : n'importe quel code à 6 chiffres est accepté.",
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _seconds > 0
                        ? Text(
                            'Renvoyer le code dans $_seconds s',
                            style: const TextStyle(color: AppColors.textMuted),
                          )
                        : TextButton(
                            onPressed: () => setState(_startTimer),
                            child: const Text('Renvoyer le code'),
                          ),
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: 'Vérifier',
              onPressed: _codeCtrl.text.length == 6 ? _verify : null,
            ),
          ),
        ],
      ),
    );
  }
}