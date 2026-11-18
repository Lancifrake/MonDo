import 'package:flutter/material.dart';
import '../../data/user_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/status_badge.dart';
import '../welcome_screen.dart';
import 'identity_screen.dart';
import 'offers_screen.dart';
import 'settings_screen.dart';

class _ProfileItem {
  _ProfileItem(this.icon, this.title, this.subtitle, this.onTap, {this.badge});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? badge;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _settings(BuildContext context, SettingsSection section) {
    _open(context, SettingsScreen(section: section));
  }

  void _logout(BuildContext context) {
    // On vide toute la pile d'écrans et on revient à l'accueil de bienvenue
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_ProfileItem>[
      _ProfileItem(
        Icons.check_circle_outline,
        'Mon identité',
        'Vérifie ton identité',
        () => _open(context, const IdentityScreen()),
        badge: 'Niveau ${demoUser.identityLevel}',
      ),
      _ProfileItem(
        Icons.workspace_premium_outlined,
        'Mon offre',
        'Ce que ton offre permet',
        () => _open(context, const OffersScreen()),
        badge: demoUser.offer,
      ),
      _ProfileItem(
        Icons.shield_outlined,
        'Sécurité',
        'Code PIN, empreinte, verrouillage',
        () => _settings(context, SettingsSection.security),
      ),
      _ProfileItem(
        Icons.smartphone_outlined,
        'Mes appareils',
        'Déconnecter un appareil',
        () => _settings(context, SettingsSection.devices),
      ),
      _ProfileItem(
        Icons.tune,
        'Profil et préférences',
        'Nom, langue, pays',
        () => _settings(context, SettingsSection.profile),
      ),
      _ProfileItem(
        Icons.notifications_none_rounded,
        'Notifications',
        'Rappels, validations, annonces',
        () => _settings(context, SettingsSection.notifications),
      ),
      _ProfileItem(
        Icons.how_to_reg_outlined,
        'Mes accords',
        'Ce que tu acceptes de partager',
        () => _settings(context, SettingsSection.consents),
      ),
      _ProfileItem(
        Icons.help_outline,
        'Aide',
        null,
        () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("L'aide arrive bientôt")),
        ),
      ),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const Text(
            'Mon profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                PersonAvatar(name: demoUser.name, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demoUser.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        demoUser.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  InkWell(
                    onTap: items[i].onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              items[i].icon,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        items[i].title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (items[i].badge != null) ...[
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        label: items[i].badge!,
                                        background: AppColors.blueBg,
                                        foreground: AppColors.link,
                                      ),
                                    ],
                                  ],
                                ),
                                if (items[i].subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    items[i].subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Se déconnecter',
            icon: Icons.logout,
            background: Colors.white,
            foreground: AppColors.textDark,
            borderColor: AppColors.border,
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}