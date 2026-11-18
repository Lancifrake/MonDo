import 'package:flutter/material.dart';
import '../../data/user_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/note_box.dart';
import '../../widgets/section_label.dart';
import '../../widgets/selectable_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/switch_card.dart';

enum SettingsSection { security, devices, profile, notifications, consents }

class _Device {
  const _Device(this.name, this.lastSeen, {this.isCurrent = false});

  final String name;
  final String lastSeen;
  final bool isCurrent;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.section = SettingsSection.security});

  final SettingsSection section; // section vers laquelle on défile à l'ouverture

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _lockOptions = {'1min': '1 min', '5min': '5 min', 'never': 'Jamais'};

  // Une clé par section : elle permet de défiler jusqu'à elle
  final Map<SettingsSection, GlobalKey> _keys = {
    for (final section in SettingsSection.values) section: GlobalKey(),
  };

  // Sécurité
  bool _biometric = false;
  String _lock = '1min';

  // Appareils
  final _devices = <_Device>[
    const _Device('Tecno Spark 10', 'Maintenant', isCurrent: true),
    const _Device('Infinix Hot 11', 'Il y a 3 mois'),
  ];

  // Profil et préférences
  final _nameCtrl = TextEditingController(text: demoUser.name);
  String _language = 'Français';
  String _country = 'Cameroun';

  // Notifications
  bool _remindersOn = true;
  bool _paymentsOn = true;
  bool _disputesOn = true;
  bool _votesOn = true;
  bool _announcementsOn = true;
  bool _smsOn = false;

  // Mes accords
  bool _analyticsOn = false;
  bool _scoreOn = false;
  bool _shareOn = false;

  @override
  void initState() {
    super.initState();
    // Une fois l'écran dessiné, on défile jusqu'à la section demandée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[widget.section]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _removeDevice(_Device device) {
    setState(() => _devices.remove(device));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${device.name} déconnecté')),
    );
  }

  // Une ligne d'interrupteur avec l'espace en dessous
  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwitchCard(
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Réglages'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _securitySection(),
            const SizedBox(height: 28),
            _devicesSection(),
            const SizedBox(height: 28),
            _profileSection(),
            const SizedBox(height: 28),
            _notificationsSection(),
            const SizedBox(height: 28),
            _consentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _securitySection() {
    return Column(
      key: _keys[SettingsSection.security],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Sécurité'),
        const SizedBox(height: 12),
        _switch(
          'Empreinte ou visage',
          'Pour ouvrir MonDo sans taper ton code PIN.',
          _biometric,
          (value) => setState(() => _biometric = value),
        ),
        const SizedBox(height: 6),
        const SectionLabel('Verrouillage automatique'),
        const SizedBox(height: 10),
        Row(
          spacing: 10,
          children: [
            for (final option in _lockOptions.entries)
              Expanded(
                child: SelectableCard(
                  compact: true,
                  title: option.value,
                  selected: _lock == option.key,
                  onTap: () => setState(() => _lock = option.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const NoteBox(
          "Les écrans de MonDo sont masqués quand tu changes d'application.",
        ),
      ],
    );
  }

  Widget _devicesSection() {
    return Column(
      key: _keys[SettingsSection.devices],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Mes appareils'),
        const SizedBox(height: 4),
        const Text(
          'Tu peux déconnecter un appareil à distance.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _devices.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.smartphone_outlined,
                          size: 18,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _devices[i].name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _devices[i].lastSeen,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_devices[i].isCurrent)
                        const StatusBadge(
                          label: 'Cet appareil',
                          background: AppColors.mint,
                          foreground: AppColors.green,
                        )
                      else
                        IconButton(
                          onPressed: () => _removeDevice(_devices[i]),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFC0392B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileSection() {
    return Column(
      key: _keys[SettingsSection.profile],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Mon profil et mes préférences'),
        const SizedBox(height: 12),
        const SectionLabel('Mon nom'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        const SectionLabel('Langue'),
        const SizedBox(height: 8),
        AppDropdown(
          value: _language,
          items: const ['Français', 'English'],
          onChanged: (value) => setState(() => _language = value),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Pays'),
        const SizedBox(height: 8),
        AppDropdown(
          value: _country,
          items: const ['Cameroun'],
          onChanged: (value) => setState(() => _country = value),
        ),
        const SizedBox(height: 8),
        const Text(
          "Devise : franc CFA (FCFA). D'autres pays et devises arrivent bientôt.",
          style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _notificationsSection() {
    return Column(
      key: _keys[SettingsSection.notifications],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Notifications'),
        const SizedBox(height: 4),
        const Text(
          'Tu peux aussi régler chaque tontine séparément.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        _switch(
          "Rappels d'échéance",
          'Avant la date limite et en cas de retard',
          _remindersOn,
          (value) => setState(() => _remindersOn = value),
        ),
        _switch(
          'Paiements validés ou refusés',
          "Chaque fois qu'on traite ton paiement",
          _paymentsOn,
          (value) => setState(() => _paymentsOn = value),
        ),
        _switch(
          'Contestations',
          'Quand un paiement est contesté',
          _disputesOn,
          (value) => setState(() => _disputesOn = value),
        ),
        _switch(
          'Votes du groupe',
          'Quand un vote est lancé ou terminé',
          _votesOn,
          (value) => setState(() => _votesOn = value),
        ),
        _switch(
          'Annonces',
          'Les messages du groupe',
          _announcementsOn,
          (value) => setState(() => _announcementsOn = value),
        ),
        _switch(
          'Rappels par SMS ou WhatsApp',
          'Pour recevoir les rappels sans internet.',
          _smsOn,
          (value) => setState(() => _smsOn = value),
        ),
      ],
    );
  }

  Widget _consentsSection() {
    return Column(
      key: _keys[SettingsSection.consents],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Mes accords'),
        const SizedBox(height: 4),
        const Text(
          "Rien n'est partagé sans ton accord. Tu peux changer d'avis à "
          'tout moment.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        _switch(
          'Utiliser mes données pour améliorer MonDo',
          'Statistiques anonymes uniquement',
          _analyticsOn,
          (value) => setState(() => _analyticsOn = value),
        ),
        _switch(
          'Calculer ma fiabilité',
          'Un score basé sur ta régularité de paiement',
          _scoreOn,
          (value) => setState(() {
            _scoreOn = value;
            // Sans score, il n'y a rien à partager
            if (!value) _shareOn = false;
          }),
        ),
        _switch(
          'La partager avec une banque ou une microfinance',
          'Seulement si tu le demandes, institution par institution',
          _shareOn,
          // null = interrupteur grisé tant que le score n'est pas activé
          _scoreOn ? (value) => setState(() => _shareOn = value) : null,
        ),
        if (!_scoreOn)
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
              children: [
                TextSpan(text: "Active d'abord le "),
                TextSpan(
                  text: 'calcul de ta fiabilité',
                  style: TextStyle(color: AppColors.amberText),
                ),
                TextSpan(text: ' pour pouvoir la partager.'),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    );
  }
}