import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cercles_provider.dart';
import '../../utils/format.dart';
import '../../widgets/sobre.dart';
import 'cercle_details_screen.dart';

String rythme(Reglement r) => switch (r.frequence) {
      'hebdomadaire' => 'chaque semaine',
      'mensuelle' => 'chaque mois',
      'jours' => 'tous les ${r.periodeJours} jours',
      _ => r.frequence,
    };

/// Tontines ouvertes qui cherchent des membres (GET /cercles/catalogue).
class CerclesCatalogScreen extends ConsumerStatefulWidget {
  const CerclesCatalogScreen({super.key});

  @override
  ConsumerState<CerclesCatalogScreen> createState() => _CatalogueState();
}

class _CatalogueState extends ConsumerState<CerclesCatalogScreen> {
  String _frequence = 'toutes';
  String _montant = 'tous';

  CatalogueFilter get _filtre => CatalogueFilter(
        frequence: _frequence == 'toutes' ? null : _frequence,
        montantMax: switch (_montant) { 'petit' => 10000, 'moyen' => 50000, _ => null },
        montantMin: switch (_montant) { 'moyen' => 10001, 'grand' => 50001, _ => null },
      );

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(catalogueCerclesProvider(_filtre));
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver une tontine')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(catalogueCerclesProvider(_filtre)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Filtres(
              choix: const {'toutes': 'Tous les rythmes', 'hebdomadaire': 'Chaque semaine', 'mensuelle': 'Chaque mois', 'jours': 'Sur mesure'},
              actif: _frequence,
              onChange: (v) => setState(() => _frequence = v),
            ),
            const SizedBox(height: 8),
            Filtres(
              choix: const {'tous': 'Tous les montants', 'petit': 'Jusqu’à 10 000', 'moyen': '10 000 à 50 000', 'grand': 'Plus de 50 000'},
              actif: _montant,
              onChange: (v) => setState(() => _montant = v),
            ),
            const SizedBox(height: 12),
            ...selon(catalogue, (liste) {
              if (liste.isEmpty) return const [Note('Aucune tontine ouverte avec ces critères.')];
              return [
                for (final c in liste)
                  Carte(
                    titre: c.nom,
                    detail: [
                      rythme(c.reglement),
                      '${c.reglement.nombreMembres} membres',
                      '${c.placesRestantes ?? '?'} place(s) libre(s)',
                      'premier tour le ${formatDate(c.reglement.datePremierTour)}',
                      if (c.reglement.scoreMinimum != null) 'score minimum ${c.reglement.scoreMinimum}',
                    ].join(' · '),
                    statut: c.scoreSuffisant == false ? 'score insuffisant' : 'à partir de la place ${c.premierePlaceAutorisee ?? 1}',
                    ton: c.scoreSuffisant == false ? Ton.gris : Ton.encre,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CercleDetailsScreen(cercleId: c.id)),
                    ),
                  ),
              ];
            }, reessayer: () => ref.invalidate(catalogueCerclesProvider(_filtre))),
          ],
        ),
      ),
    );
  }
}
