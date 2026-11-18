import 'package:flutter/material.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/step_progress.dart';
import 'info_step.dart';
import 'model_step.dart';

class CreateTontineScreen extends StatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  State<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends State<CreateTontineScreen> {
  final _draft = TontineDraft();
  int _step = 0; // 0 = étape 1

  // Le choix « tout régler moi-même » ajoute deux étapes
  int get _totalSteps => _draft.customAll ? 8 : 6;

  String get _title => switch (_step) {
        0 => 'Ton modèle',
        1 => 'Ta tontine',
        _ => 'À venir',
      };

  // Le bouton Continuer est grisé tant que l'étape n'est pas valide
  bool get _canContinue {
    if (_step == 1) return _draft.name.trim().isNotEmpty;
    return true;
  }

  void _refresh() => setState(() {});

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
    // Dernière étape : la création de la tontine viendra plus tard
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return ModelStep(draft: _draft, onChanged: _refresh);
      case 1:
        return InfoStep(draft: _draft, onChanged: _refresh);
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
                key: ValueKey(_step), // remet le défilement en haut à chaque étape
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