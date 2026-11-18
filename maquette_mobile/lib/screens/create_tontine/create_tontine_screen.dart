import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/step_progress.dart';
import 'contribution_step.dart';
import 'info_step.dart';
import 'model_step.dart';
import 'roles_step.dart';
import 'signature_pin_step.dart';
import 'summary_step.dart';
import 'turns_step.dart';

class CreateTontineScreen extends StatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final _draft = TontineDraft();
  int _step = 0; // 0 = étape 1
  bool _confirmingPin = false; // true = on demande le PIN pour signer

  // Le choix « tout régler moi-même » ajoute deux étapes
  int get _totalSteps => _draft.customAll ? 8 : 6;

  // Le résumé est toujours la dernière étape
  bool get _isLast => _step == _totalSteps - 1;

  String get _title {
    if (_isLast) return 'Résumé et signature';
    return switch (_step) {
      0 => 'Ton modèle',
      1 => 'Ta tontine',
      2 => 'La cotisation',
      3 => 'Les tours et le bénéficiaire',
      4 => 'Les rôles',
      _ => 'À venir',
    };
  }

  // Le bouton Continuer est grisé tant que l'étape n'est pas valide
  bool get _canContinue {
    if (_step == 1) return _draft.name.trim().isNotEmpty;
    if (_step == 2) return _draft.amount >= 500; // minimum 500 FCFA
    return true;
  }

  void _refresh() => setState(() {});

  void _next() {
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _back() {
    // Sur l'écran du PIN, on revient au résumé au lieu de reculer d'une étape
    if (_confirmingPin) {
      setState(() => _confirmingPin = false);
      return;
    }
    if (_step > 0) setState(() => _step--);
  }

  void _startSigning() => setState(() => _confirmingPin = true);

  void _sign() {
    // Temporaire : l'envoi de la tontine au serveur viendra plus tard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tontine créée')),
    );
    Navigator.pop(context);
  }

  Widget _buildStep() {
    // Dernière étape : résumé, puis confirmation par PIN
    if (_isLast) {
      return _confirmingPin
          ? SignaturePinStep(onConfirmed: _sign, onCancel: _back)
          : SummaryStep(draft: _draft, onSign: _startSigning, onEdit: _back);
    }

    switch (_step) {
      case 0:
        return ModelStep(draft: _draft, onChanged: _refresh);
      case 1:
        return InfoStep(draft: _draft, onChanged: _refresh);
      case 2:
        return ContributionStep(draft: _draft, onChanged: _refresh);
      case 3:
        return TurnsStep(draft: _draft, onChanged: _refresh);
      case 4:
        return RolesStep(draft: _draft, onChanged: _refresh);
      default:
        return const Text(
          'Cette étape arrive bientôt.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope : le bouton retour d'Android recule d'une étape
    // au lieu de fermer tout l'assistant
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: buildAppBar(
          context,
          'Créer une tontine',
          onBack: _step == 0 ? null : _back,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // remet le défilement en haut à chaque changement d'écran
                key: ValueKey('$_step-$_confirmingPin'),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Étape ${_step + 1} sur $_totalSteps',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StepProgress(current: _step + 1, total: _totalSteps),
                    const SizedBox(height: 20),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStep(),
                  ],
                ),
              ),
            ),
            // Pas de barre Retour / Continuer sur le résumé
            if (!_isLast)
              BottomBar(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Opacity(
                        opacity: _step == 0 ? 0.5 : 1,
                        child: AppButton(
                          label: 'Retour',
                          background: Colors.white,
                          foreground: AppColors.textDark,
                          borderColor: AppColors.border,
                          onPressed: _step == 0 ? null : _back,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AppButton(
                        label: 'Continuer',
                        onPressed: _canContinue ? _next : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}