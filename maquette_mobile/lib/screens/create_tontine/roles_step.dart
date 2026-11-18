import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/check_card.dart';
import '../../widgets/section_label.dart';

class RolesStep extends StatefulWidget {
  const RolesStep({super.key, required this.draft, required this.onChanged});

  final TontineDraft draft;
  final VoidCallback onChanged;

  @override
  State<RolesStep> createState() => _RolesStepState();
}

class _RolesStepState extends State<RolesStep> {
  final _roleCtrl = TextEditingController();

  TontineDraft get d => widget.draft;

  List<String> get _allRoles => [...predefinedRoles, ...d.customRoles];

  // On peut ajouter un poste s'il a un nom et n'existe pas déjà
  bool get _canAdd {
    final name = _roleCtrl.text.trim();
    if (name.isEmpty) return false;
    return !_allRoles.any((r) => r.toLowerCase() == name.toLowerCase());
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    change();
    widget.onChanged();
  }

  void _addRole() {
    final name = _roleCtrl.text.trim();
    _roleCtrl.clear();
    _update(() {
      d.customRoles.add(name);
      d.roles.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Les postes cochés, sauf le président (que l'utilisateur tient d'office)
    final otherRoles =
        _allRoles.where((r) => d.roles.contains(r) && r != 'Président');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chaque poste a ses droits (ils sont réglables plus tard). '
          'Tout membre peut déclarer ses paiements, les contester et voir '
          'les comptes.',
          style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Postes de ta tontine'),
        const SizedBox(height: 10),
        for (final role in _allRoles) ...[
          CheckCard(
            label: role,
            checked: d.roles.contains(role),
            trailing: role == 'Président' ? 'Obligatoire' : null,
            onChanged: role == 'Président'
                ? null
                : (value) => _update(() {
                      if (value) {
                        d.roles.add(role);
                      } else {
                        d.roles.remove(role);
                        d.heldRoles.remove(role);
                      }
                    }),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        const Text(
          'Postes à ta façon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        const SectionLabel('Nom du nouveau poste'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _roleCtrl,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ex. Responsable des événements',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                onPressed: _canAdd ? _addRole : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.green.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Un nouveau poste commence avec les droits de base ; '
          'tu pourras cocher ses autres droits ensuite.',
          style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Les postes que tu tiens'),
        const SizedBox(height: 4),
        const Text(
          'Tu seras président. Tu peux tenir d\'autres postes au début et '
          'les confier plus tard.',
          style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        for (final role in otherRoles) ...[
          CheckCard(
            label: role,
            checked: d.heldRoles.contains(role),
            onChanged: (value) => _update(() {
              if (value) {
                d.heldRoles.add(role);
              } else {
                d.heldRoles.remove(role);
              }
            }),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}