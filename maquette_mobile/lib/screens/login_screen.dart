import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/section_label.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();

  // Un numéro camerounais a 9 chiffres
  bool get _isValid => _phoneCtrl.text.length == 9;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(phone: _phoneCtrl.text, isLogin: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Connexion'),
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
                  const SectionLabel('Numéro de téléphone'),
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