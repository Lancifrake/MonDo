import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/bottom_bar.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Le bouton s'active quand le nom est rempli et le numéro a 9 chiffres
  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.length == 9;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(phone: _phoneCtrl.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Créer mon compte'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: "Nous t'envoyons un code à "),
                        TextSpan(
                          text: '6 chiffres',
                          style: TextStyle(
                            color: AppColors.link,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' pour vérifier ton numéro.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FieldLabel('Nom complet'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'Amina Njoya'),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Numéro de téléphone'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6ECE6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '+237',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration:
                              const InputDecoration(hintText: '6 99 42 18 06'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Recevoir le code par SMS',
                  onPressed: _isValid ? _submit : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  "En continuant, tu acceptes les conditions d'utilisation\n"
                  'et la politique de confidentialité.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}