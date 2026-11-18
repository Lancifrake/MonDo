import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/user_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  // Photos « prises » (simulées, comme dans la maquette)
  bool _recto = false;
  bool _verso = false;
  bool _selfie = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool get _documentsReady => _recto && _verso && _selfie;
  bool get _contactReady =>
      _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.length == 9;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Mon identité'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Niveau actuel
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau ${demoUser.identityLevel}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tu peux parcourir et rejoindre des tontines privées.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatusBadge(
                  label: 'Basique',
                  background: AppColors.mint,
                  foreground: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Passer au niveau 2
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Passer au niveau 2',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nécessaire pour rejoindre une tontine ouverte à des '
                  'inconnus, recevoir une cagnotte ou dépasser un certain '
                  'montant.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                _PhotoButton(
                  label: "Carte d'identité : recto",
                  done: _recto,
                  onTap: () => setState(() => _recto = true),
                ),
                const SizedBox(height: 10),
                _PhotoButton(
                  label: "Carte d'identité : verso",
                  done: _verso,
                  onTap: () => setState(() => _verso = true),
                ),
                const SizedBox(height: 10),
                _PhotoButton(
                  label: 'Selfie',
                  done: _selfie,
                  onTap: () => setState(() => _selfie = true),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Aperçu : la caméra n'est pas disponible ici, la prise de "
                  'photo est simulée.',
                  style: TextStyle(fontSize: 11, height: 1.3, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Envoyer pour vérification',
                  onPressed: _documentsReady
                      ? () => _message('Documents envoyés pour vérification')
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Contact de confiance
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact de confiance (facultatif)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Une personne prévient si tu perds ton téléphone. Elle ne "
                  "s'engage à rien financièrement.",
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Nom'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: '6 99 42 18 06'),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Envoyer la demande par SMS',
                  onPressed: _contactReady
                      ? () => _message(
                            'Demande envoyée à ${_nameCtrl.text.trim()}',
                          )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bouton « prendre une photo » : devient vert une fois la photo prise
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.label,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? AppColors.mint : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: done ? AppColors.green : AppColors.border,
          width: done ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.photo_camera_outlined,
                size: 20,
                color: done ? AppColors.green : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              if (done)
                const Text(
                  'Pris',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}