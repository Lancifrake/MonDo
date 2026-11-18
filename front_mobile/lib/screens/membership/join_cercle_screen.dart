import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cercles_provider.dart';
import '../../models/api_models.dart';
import '../../providers/api_client_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';

/// Écran pour adhérer à un cercle
/// 
/// Permet à l'utilisateur de rejoindre un cercle ouvert
/// en sélectionnant sa place préférée si l'ordre n'est pas fixe.
/// 
/// Endpoints API utilisés:
/// - POST /cercles/:id/adhesions (adhérer à un cercle)
class JoinCercleScreen extends ConsumerStatefulWidget {
  final String cercleId;
  final Cercle cercle;

  const JoinCercleScreen({
    super.key,
    required this.cercleId,
    required this.cercle,
  });

  @override
  ConsumerState<JoinCercleScreen> createState() => _JoinCercleScreenState();
}

class _JoinCercleScreenState extends ConsumerState<JoinCercleScreen> {
  int? _selectedPlace;
  bool _isLoading = false;
  String? _error;
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adhérer au Cercle'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cercle.nom ?? 'Cercle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Montant: ${formatAmount(widget.cercle.reglement.montant)} '
                      'chaque ${widget.cercle.reglement.frequence}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sélection de place
              if (widget.cercle.reglement.ordreFixe == null ||
                  widget.cercle.reglement.ordreFixe!.isEmpty)
                _SelectionPlace(
                  cercle: widget.cercle,
                  selectedPlace: _selectedPlace,
                  onPlaceSelected: (place) {
                    setState(() {
                      _selectedPlace = place;
                      _error = null;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Réglement
              _ReglementResume(reglement: widget.cercle.reglement),

              const SizedBox(height: 24),

              // Conditions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  '⚠️ En adhérant, vous vous engagez à participer à tous les tours '
                  'et à respecter le réglement du cercle. Les défauts de paiement '
                  'affecteront votre score de confiance.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Acceptation conditions
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                    _error = null;
                  });
                },
                title: const Text(
                  'J\'ai lu et j\'accepte les conditions d\'adhésion',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              // Affichage d'erreur
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) const SizedBox(height: 16),

              // Boutons
              AppButton(
                label: _isLoading ? 'Adhésion en cours...' : 'Confirmer l\'Adhésion',
                onPressed: _isLoading || !_acceptedTerms ? null : _join,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _join() async {
    // Valider
    if (!_acceptedTerms) {
      setState(() {
        _error = 'Veuillez accepter les conditions d\'adhésion';
      });
      return;
    }


    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Adhésion signée : l'engagement reprend l'empreinte du règlement.
      await ref.read(cerclesServiceProvider).adhererAuCercle(
            cercle: widget.cercle,
            placeSouhaitee: _selectedPlace ?? widget.cercle.reglement.nombreMembres,
          );
      ref.invalidate(mesCerclesRefreshableProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adhésion réussie ! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Retour après 2 secondes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur inattendue: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Sélection de place pour adhérer
class _SelectionPlace extends StatelessWidget {
  final Cercle cercle;
  final int? selectedPlace;
  final Function(int) onPlaceSelected;

  const _SelectionPlace({
    required this.cercle,
    required this.selectedPlace,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final placesDisponibles =
        cercle.placesRestantes ?? cercle.reglement.nombreMembres - cercle.membres.length;
    // Le score décide des premières places permises ; l'ordre final est fixé par le serveur.
    final premiere = cercle.premierePlaceAutorisee ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez Votre Place',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$placesDisponibles place(s) libre(s). Place souhaitée : à partir de la $premiere selon ton score.',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: cercle.reglement.nombreMembres,
          itemBuilder: (context, index) {
            final placeNumber = index + 1;
            final isOccupied = placeNumber < premiere; // non permise pour ce score
            final isSelected = selectedPlace == placeNumber;

            return GestureDetector(
              onTap: !isOccupied
                  ? () => onPlaceSelected(placeNumber)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : isOccupied
                          ? Colors.grey.shade300
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOccupied ? '✓' : placeNumber.toString(),
                        style: TextStyle(
                          fontSize: isOccupied ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isOccupied
                                  ? Colors.grey
                                  : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Résumé du réglement
class _ReglementResume extends StatelessWidget {
  final Reglement reglement;

  const _ReglementResume({required this.reglement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réglement du Cercle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ReglementItem(
            label: 'Montant par tour',
            value: formatAmount(reglement.montant),
          ),
          const SizedBox(height: 8),
          _ReglementItem(
            label: 'Fréquence',
            value: reglement.frequence,
          ),
          const SizedBox(height: 8),
          _ReglementItem(
            label: 'Nombre de tours',
            value: '${reglement.nombreMembres}',
          ),
          if (reglement.penaliteRetard != null) ...[
            const SizedBox(height: 8),
            _ReglementItem(
              label: 'Pénalité de retard',
              value: formatAmount(reglement.penaliteRetard!),
            ),
          ],
          if (reglement.delaiGraceJours != null) ...[
            const SizedBox(height: 8),
            _ReglementItem(
              label: 'Délai de grâce',
              value: '${reglement.delaiGraceJours} jours',
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de réglement
class _ReglementItem extends StatelessWidget {
  final String label;
  final String value;

  const _ReglementItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
