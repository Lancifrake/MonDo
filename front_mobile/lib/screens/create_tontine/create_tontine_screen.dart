import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cercles_provider.dart';
import '../../data/tontine_draft.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/step_progress.dart';
import 'info_step.dart';
import 'model_step.dart';
import 'reglement_step.dart';

class CreateTontineScreen extends ConsumerStatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  ConsumerState<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends ConsumerState<CreateTontineScreen> {
  final _draft = TontineDraft();
  bool _envoi = false;
  int _step = 0; // 0 = étape 1

  static const _totalSteps = 3;
  bool get _derniere => _step == _totalSteps - 1;

  String get _title => switch (_step) {
        0 => 'Ton modèle',
        1 => 'Ta tontine',
        _ => 'Ton règlement',
      };

  // Le bouton est grisé tant que l'étape n'est pas valide
  bool get _canContinue {
    if (_step == 1) return _draft.montant > 0;
    if (_derniere && _draft.problemeOrdre(ref.read(authStateProvider).compte?.id) != null) return false;
    return !_envoi;
  }

  /// Signe le règlement et crée la tontine (POST /cercles).
  Future<void> _creer() async {
    setState(() => _envoi = true);
    try {
      final d = _draft;
      await ref.read(cerclesServiceProvider).createCercle(
            montant: d.montant,
            frequence: d.frequence,
            periodeJours: d.frequence == 'jours' ? d.periodeJours : null,
            nombreMembres: d.nombreMembres,
            ouvert: !d.isPrivate,
            datePremierTour: d.datePremierTour,
            penaliteRetard: d.penaliteRetard,
            delaiGraceJours: d.delaiGraceJours,
            scoreMinimum: d.isPrivate || (d.scoreMinimum ?? 0) == 0 ? null : d.scoreMinimum,
            rappelsAvantEcheanceJours: d.rappels ? const [3, 1] : null,
            parrainageAccepte: !d.isPrivate && d.parrainageAccepte,
            placeSouhaitee: d.placeSouhaitee == null ? null : d.placeSouhaitee!.clamp(1, d.nombreMembres),
            ordreFixe: d.ordreASigner,
          );
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(catalogueCerclesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tontine créée. Invite tes membres pour la compléter.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _refresh() => setState(() {});

  void _next() {
    if (_derniere) {
      _creer();
    } else {
      setState(() => _step++);
    }
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
        return ReglementStep(draft: _draft, onChanged: _refresh);
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
                        fontWeight: FontWeight.w600,
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
                      label: _derniere ? 'Signer et créer' : 'Continuer',
                      onPressed: _canContinue ? _next : null,
                      isLoading: _envoi,
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