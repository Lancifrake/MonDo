import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/bottom_bar.dart';
import 'pin_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.nom});

  final String phone;
  final String nom;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _envoi = false;
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

  /// Le code SMS est vérifié par le serveur DANS l'inscription (POST /comptes).
  Future<void> _verify() async {
    setState(() => _envoi = true);
    try {
      await ref.read(authStateProvider.notifier).signup(
            phoneNumber: '+237${widget.phone}',
            nom: widget.nom,
            otp: _codeCtrl.text,
          );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _renvoyer() async {
    setState(_startTimer);
    try {
      await ref.read(authStateProvider.notifier).requestOtp('+237${widget.phone}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
    }
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
                  const SizedBox(height: 24),
                  Center(
                    child: _seconds > 0
                        ? Text(
                            'Renvoyer le code dans $_seconds s',
                            style: const TextStyle(color: AppColors.textMuted),
                          )
                        : TextButton(
                            onPressed: _renvoyer,
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
              isLoading: _envoi,
            ),
          ),
        ],
      ),
    );
  }
}