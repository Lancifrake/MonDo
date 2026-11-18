import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api_models.dart';
import '../../providers/cercles_provider.dart';
import '../../widgets/sobre.dart';
import 'vie_cercle_screens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/cotisations_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/app_button.dart';
import '../membership/join_cercle_screen.dart';

/// Écran de détails d'un cercle (tontine)
/// 
/// Affiche les informations complètes d'un cercle:
/// - Réglement (montant, fréquence, nombre de membres)
/// - Liste des membres
/// - État des cotisations par tour
/// - Historique des échanges
/// 
/// Endpoints API utilisés:
/// - GET /cercles/:id (récupérer détails cercle)
/// - GET /cercles/:id/etat (état des cotisations)
/// - GET /cercles/:id/echanges (historique)
class CercleDetailsScreen extends ConsumerWidget {
  final String cercleId;

  const CercleDetailsScreen({
    super.key,
    required this.cercleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer détails du cercle
    final cercleAsync = ref.watch(cercleProvider(cercleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Cercle'),
        elevation: 0,
      ),
      body: cercleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(cercleProvider(cercleId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (cercle) {
          final moi = ref.read(apiClientProvider).membreId;
          final estMembre = cercle.membres.contains(moi);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                _CercleHeader(cercle: cercle),

                const SizedBox(height: 24),

                // Réglement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ReglementSection(reglement: cercle.reglement),
                ),

                const SizedBox(height: 24),

                // Membres
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MembresSection(cercle: cercle),
                ),

                const SizedBox(height: 24),

                // État des cotisations et échanges : réservés aux membres du cercle
                if (estMembre && cercle.statut != 'en_attente') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EtatCotisationsSection(cercleId: cercleId),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _EchangesSection(cercleId: cercleId),
                  ),
                  const SizedBox(height: 32),
                ],

                if (estMembre)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActionsMembre(cercle: cercle, organisateur: cercle.organisateurId == moi),
                  ),

                // Actions
                if (!estMembre && cercle.statut == 'en_attente')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JoinCercleScreen(
                                cercleId: cercleId,
                                cercle: cercle,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Rejoindre ce Cercle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// En-tête du cercle avec nom et statut
class _CercleHeader extends StatelessWidget {
  final Cercle cercle;

  const _CercleHeader({required this.cercle});

  Color _getStatusColor() {
    switch (cercle.statut) {
      case 'en_attente':
        return Colors.amber;
      case 'complet':
        return Colors.blue;
      case 'termine':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (cercle.statut) {
      case 'en_attente':
        return 'En attente de membres';
      case 'complet':
        return 'Cercle complet';
      case 'termine':
        return 'Terminé';
      default:
        return cercle.statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cercle.nom ?? 'Cercle',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (cercle.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        cercle.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoCard(
                label: 'Organisateur',
                value: cercle.organisateurId == null ? '—' : '${cercle.organisateurId!.substring(0, 8)}…',
              ),
              _InfoCard(
                label: 'Membres',
                value: '${cercle.membres.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card d'information simple
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section réglement
class _ReglementSection extends StatelessWidget {
  final Reglement reglement;

  const _ReglementSection({required this.reglement});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réglement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _ReglementRow(
                label: 'Montant par tour',
                value: formatAmount(reglement.montant),
              ),
              const SizedBox(height: 12),
              _ReglementRow(
                label: 'Fréquence',
                value: reglement.frequence,
              ),
              const SizedBox(height: 12),
              _ReglementRow(
                label: 'Nombre de membres',
                value: '${reglement.nombreMembres}',
              ),
              if (reglement.penaliteRetard != null) ...[
                const SizedBox(height: 12),
                _ReglementRow(
                  label: 'Pénalité de retard',
                  value: formatAmount(reglement.penaliteRetard!),
                ),
              ],
              if (reglement.delaiGraceJours != null) ...[
                const SizedBox(height: 12),
                _ReglementRow(
                  label: 'Délai de grâce',
                  value: '${reglement.delaiGraceJours} jours',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Ligne de réglement
class _ReglementRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReglementRow({
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
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Section membres : l'ordre de passage. Le serveur ne donne pas les noms des autres membres.
class _MembresSection extends ConsumerWidget {
  final Cercle cercle;

  const _MembresSection({required this.cercle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moi = ref.read(apiClientProvider).membreId;
    final ordre = [...?cercle.ordre]..sort((a, b) => a.position.compareTo(b.position));
    final inscrits = cercle.membres.isNotEmpty
        ? cercle.membres.length
        : cercle.reglement.nombreMembres - (cercle.placesRestantes ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Titre('Membres'),
        Bloc(enfants: [
          Ligne('Inscrits', valeur: '$inscrits sur ${cercle.reglement.nombreMembres}'),
          for (final o in ordre)
            Ligne(
              'Place ${o.position}${o.membreId == moi ? ' · moi' : ''}${o.membreId == cercle.organisateurId ? ' · organisateur' : ''}',
              valeur: o.position == 1 ? 'reçoit en premier' : null,
            ),
        ]),
        if (ordre.isEmpty)
          const Note('L’ordre de passage est fixé quand toutes les places sont prises.'),
      ],
    );
  }
}

/// Section état des cotisations
class _EtatCotisationsSection extends ConsumerWidget {
  final String cercleId;

  const _EtatCotisationsSection({required this.cercleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatAsync = ref.watch(etatCotisationsCercleProvider(cercleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'État des Cotisations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        etatAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Erreur: $error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          data: (etat) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: etat.tours.length,
              itemBuilder: (context, index) {
                final tour = etat.tours[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tour ${tour.numero}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tour.membres.map((membre) {
                        Color statusColor;
                        String statusIcon;
                        switch (membre.statut) {
                          case 'due':
                            statusColor = Colors.red;
                            statusIcon = 'à payer';
                            break;
                          case 'declaree':
                            statusColor = Colors.orange;
                            statusIcon = 'déclaré';
                            break;
                          case 'confirmee':
                            statusColor = Colors.green;
                            statusIcon = 'payé';
                            break;
                          default:
                            statusColor = Colors.grey;
                            statusIcon = membre.statut;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  membre.id == ref.read(apiClientProvider).membreId ? 'Moi' : 'Membre ${membre.id.substring(0, 4)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                formatAmount(membre.montant),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(statusIcon),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Section historique des échanges
class _EchangesSection extends ConsumerWidget {
  final String cercleId;

  const _EchangesSection({required this.cercleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final echangesAsync = ref.watch(echangesCercleProvider(cercleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des Échanges',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        echangesAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Erreur: $error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          data: (echanges) {
            if (echanges.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun échange pour le moment',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: echanges.length,
              itemBuilder: (context, index) {
                final echange = echanges[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              echange['type'] ?? 'Échange',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            echange['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (echange['details'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          echange['details'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}


/// Actions d'un membre : inviter (organisateur, cercle en attente) et démonstration.
class _ActionsMembre extends ConsumerWidget {
  const _ActionsMembre({required this.cercle, required this.organisateur});

  final Cercle cercle;
  final bool organisateur;

  Future<void> _faire(BuildContext context, WidgetRef ref, Future<Object?> Function() action, String ok) async {
    try {
      await action();
      ref.invalidate(cercleProvider(cercle.id));
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(mesCotisationsRefreshableProvider);
      ref.invalidate(etatCotisationsCercleProvider(cercle.id));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreur(e))));
      }
    }
  }

  Future<void> _inviter(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final numero = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inviter par numéro'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(prefixText: '+237 ', hintText: '6 99 42 18 06'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, '+237${ctrl.text.replaceAll(' ', '')}'),
            child: const Text('Envoyer le SMS'),
          ),
        ],
      ),
    );
    if (numero == null || !context.mounted) return;
    await _faire(
      context,
      ref,
      () => ref.read(cerclesServiceProvider).inviterMembre(cercleId: cercle.id, numeroTelephone: numero),
      'Invitation envoyée par SMS.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(cerclesServiceProvider);
    final espace = ref.read(espaceServiceProvider);
    void ouvrir(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    final enCours = cercle.statut == 'complet';
    final autres = [...?cercle.ordre]..sort((a, b) => a.position.compareTo(b.position));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Bloc(enfants: [
          Ligne('Registre et preuve d’intégrité', onTap: () => ouvrir(RegistreScreen(cercleId: cercle.id))),
          if (enCours) Ligne('Échanges de places', onTap: () => ouvrir(EchangesScreen(cercle: cercle))),
          if (organisateur) Ligne('Assistant de l’organisateur', onTap: () => ouvrir(AssistantScreen(cercle: cercle))),
        ]),
        if (enCours && autres.isNotEmpty) ...[
          const Titre('Dossier de preuve d’un membre en défaut'),
          Bloc(enfants: [
            for (final o in autres.where((o) => o.membreId != espace.moi))
              Ligne('Place ${o.position}', onTap: () => ouvrir(DossierPreuveScreen(cercle: cercle, membreId: o.membreId))),
          ]),
        ],
        const SizedBox(height: 16),
        if (organisateur && cercle.statut == 'en_attente') ...[
          ElevatedButton.icon(
            onPressed: () => _inviter(context, ref),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Inviter un membre'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _faire(context, ref, () => service.demoMembresFictifs(cercle.id),
                'Tontine complétée avec des membres fictifs.'),
            child: const Text('Démo : compléter avec des membres fictifs'),
          ),
        ],
        if (enCours) ...[
          OutlinedButton(
            onPressed: () => _faire(context, ref, () => service.demoSuite(cercle.id),
                'Les membres fictifs ont joué le tour en cours.'),
            child: const Text('Démo : les autres membres jouent le tour'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Quitter la tontine ?'),
                  content: const Text(
                    'Possible seulement avant d’avoir reçu. Ce que tu as versé te sera remboursé selon le règlement, '
                    'et le départ est inscrit au registre.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitter')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await _faire(context, ref, () => espace.quitter(cercle.id), 'Tu as quitté la tontine.');
              }
            },
            child: const Text('Quitter la tontine', style: TextStyle(color: Color(0xFFB45309))),
          ),
        ],
        if (organisateur && cercle.statut == 'termine')
          ElevatedButton(
            onPressed: () async {
              final r = cercle.reglement;
              await _faire(
                context,
                ref,
                () => service.createCercle(
                  montant: r.montant,
                  frequence: r.frequence,
                  periodeJours: r.periodeJours,
                  nombreMembres: r.nombreMembres,
                  ouvert: r.ouvert,
                  datePremierTour: DateTime.now().add(const Duration(days: 7)),
                  penaliteRetard: r.penaliteRetard,
                  delaiGraceJours: r.delaiGraceJours,
                  scoreMinimum: r.scoreMinimum,
                  cerclePrecedentId: cercle.id,
                ),
                'Nouveau cycle créé : les anciens membres sont invités à signer de nouveau.',
              );
            },
            child: const Text('Relancer un nouveau cycle'),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}
