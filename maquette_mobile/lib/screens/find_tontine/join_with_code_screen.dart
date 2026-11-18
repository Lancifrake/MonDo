import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/section_label.dart';
import 'tontine_detail_screen.dart';

/// Un QR code peut contenir le code seul ou un lien qui le contient
/// (par exemple https://mondo.app/invitation?code=FAMILLE-1103).
String extractInviteCode(String raw) {
  final value = raw.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    return uri.queryParameters['code'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : value);
  }
  return value;
}

class JoinWithCodeScreen extends StatefulWidget {
  const JoinWithCodeScreen({super.key});

  @override
  State<JoinWithCodeScreen> createState() => _JoinWithCodeScreenState();
}

class _JoinWithCodeScreenState extends State<JoinWithCodeScreen> {
  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 18,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );

  final _codeCtrl = TextEditingController();
  String? _error;

  bool get _canSubmit => _codeCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit(String code) {
    final tontine = findByInviteCode(code);
    if (tontine == null) {
      setState(() => _error =
          'Ce code ne correspond à aucune tontine. Vérifie-le et réessaie.');
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TontineDetailScreen(tontine: tontine, invited: true),
      ),
    );
  }

  void _scan() {
    // Le vrai scanner arrive à l'étape B
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Le scan du QR code arrive bientôt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Rejoindre avec un code'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tape le code reçu par lien, SMS ou WhatsApp, ou scanne '
                    'le QR code du président.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel("Code d'invitation"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeCtrl,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    style: _monoStyle,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) _submit(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'FAMILLE-1103',
                      hintStyle: _monoStyle.copyWith(
                        color: const Color(0xFFB3B9B5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC0392B),
                      ),
                    )
                  else
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          TextSpan(text: 'Aperçu : essaie '),
                          TextSpan(
                            text: 'FAMILLE-1103',
                            style: TextStyle(color: AppColors.link),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Scanner un QR code',
                    icon: Icons.qr_code_scanner,
                    background: Colors.white,
                    foreground: AppColors.textDark,
                    borderColor: AppColors.border,
                    onPressed: _scan,
                  ),
                ],
              ),
            ),
          ),
          BottomBar(
            child: AppButton(
              label: 'Voir la tontine',
              onPressed:
                  _canSubmit ? () => _submit(_codeCtrl.text) : null,
            ),
          ),
        ],
      ),
    );
  }
}