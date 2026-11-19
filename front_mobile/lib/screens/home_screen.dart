import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../data/mock_data.dart' show Echeance;
import '../models/api_models.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cercles_provider.dart';
import '../providers/cotisations_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/echeance_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/sobre.dart' show EtatVide, Note, Squelette;
import '../widgets/cercle_des_tours.dart';
import 'cercles/cercle_details_screen.dart';
import 'cercles/cercles_catalog_screen.dart';
import 'cotisations/cotisations_list_screen.dart';
import 'cotisations/payment_declare_screen.dart';
import 'create_tontine/create_tontine_screen.dart';

const _mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

/// Accueil : mes tontines et mes échéances, lues sur le serveur.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compte = ref.watch(authStateProvider).compte;
    final moi = ref.read(apiClientProvider).membreId;
    final cerclesAsync = ref.watch(mesCerclesRefreshableProvider);
    final cotisationsAsync = ref.watch(mesCotisationsRefreshableProvider);

    final cercles = cerclesAsync.valueOrNull ?? const <ResumeCercle>[];
    final cotisations = cotisationsAsync.valueOrNull ?? const <Cotisation>[];
    final aPayer = cotisations.where((c) => c.payeurId == moi && c.statut == 'due').toList()
      ..sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
    final aValider = cotisations.where((c) => c.beneficiaireId == moi && c.statut == 'declaree').length;
    final verse = cotisations
        .where((c) => c.payeurId == moi && c.statut == 'confirmee')
        .fold<int>(0, (t, c) => t + c.montant);
    final nomDe = {for (final c in cercles) c.id: c.nom};
    final tours = {for (final c in cercles) c.id: tourEnCours(c, cotisations)};
    final prochaine = _prochaineCagnotte(cercles, tours);

    Future<void> rafraichir() async {
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(mesCotisationsRefreshableProvider);
    }

    // Pas de barre d'app ici : on fixe nous-mêmes les icônes système en foncé (heure, batterie).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: rafraichir,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espace.ecran, Espace.base, Espace.ecran, Espace.lg),
          children: [
            _Header(nom: compte?.nom ?? ''),
            const SizedBox(height: Espace.lg),
            // L'action à faire (payer) passe avant le solde.
            if (aPayer.isNotEmpty) ...[
              _NextContributionCard(cotisation: aPayer.first, nomCercle: nomDe[aPayer.first.cercleId] ?? 'ta tontine'),
              const SizedBox(height: Espace.base),
            ],
            if (aValider > 0) ...[
              _PendingPaymentsBanner(nombre: aValider),
              const SizedBox(height: Espace.base),
            ],
            _BalanceCard(
              prochaine: prochaine,
              tourDe: tours,
              total: verse,
              tontines: cercles.length,
              aPayer: aPayer.length,
              enPreparation: cercles.where((c) => c.statut == 'en_attente').length,
            ),
            const SizedBox(height: Espace.base),
            const _QuickActions(),
            const SizedBox(height: Espace.xl),
            _SectionTitle('Mes tontines', nombre: cercles.isEmpty ? null : cercles.length),
            const SizedBox(height: Espace.md),
            if (cerclesAsync.isLoading && cercles.isEmpty) const Squelette(),
            if (cerclesAsync.hasError) ...[
              Note(messageErreur(cerclesAsync.error!)),
              Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: rafraichir, child: const Text('Réessayer'))),
            ],
            if (!cerclesAsync.isLoading && cercles.isEmpty && !cerclesAsync.hasError)
              EtatVide(
                icone: Icons.groups_outlined,
                titre: 'Aucune tontine pour l’instant',
                texte: 'Crée la tienne avec tes proches, ou rejoins une tontine ouverte qui cherche des membres.',
                action: 'Trouver une tontine',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CerclesCatalogScreen())),
              ),
            if (cercles.isNotEmpty)
              // Le carrousel déborde de la marge de l'écran : les cartes défilent jusqu'au bord.
              LayoutBuilder(
                builder: (context, contraintes) => SizedBox(
                height: 232,
                child: OverflowBox(
                maxWidth: contraintes.maxWidth + 2 * Espace.ecran,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Espace.ecran),
                  itemCount: cercles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Espace.md),
                  itemBuilder: (context, i) {
                    final c = cercles[i];
                    final aPayerIci = aPayer.where((x) => x.cercleId == c.id).firstOrNull;
                    return _CarteTontine(
                      cercle: c,
                      tour: tours[c.id] ?? 0,
                      aPayer: aPayerIci,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CercleDetailsScreen(cercleId: c.id)),
                      ),
                    );
                  },
                ),
                ),
                ),
              ),
            // La première échéance est déjà dans la carte du haut : on liste les suivantes.
            if (aPayer.length > 1) ...[
              const SizedBox(height: Espace.lg),
              const _SectionTitle('Échéances suivantes'),
              const SizedBox(height: Espace.md),
              for (final e in aPayer.skip(1).take(5)) ...[
                EcheanceCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentDeclareScreen(cotisationId: e.id, cotisation: e)),
                  ),
                  echeance: Echeance(
                    day: DateTime.parse(e.dateLimite).toLocal().day.toString().padLeft(2, '0'),
                    month: _mois[DateTime.parse(e.dateLimite).toLocal().month - 1],
                    title: nomDe[e.cercleId] ?? 'Tontine',
                    subtitle: 'Tour ${e.tour} · ${formatAmount(e.montant)} FCFA',
                  ),
                ),
                const SizedBox(height: Espace.sm),
              ],
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.nombre});

  final String text;
  final int? nombre;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        if (nombre != null) ...[
          const SizedBox(width: Espace.sm),
          Text('$nombre', style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Tour en cours d'une tontine, déduit de mes cotisations : 0 si elle n'a pas commencé,
/// au-delà du nombre de membres si elle est terminée.
int tourEnCours(ResumeCercle c, List<Cotisation> cotisations) {
  final n = c.nombreMembresCible;
  if (c.statut == 'termine') return n + 1;
  if (c.statut == 'en_attente') return 0;
  final ici = cotisations.where((x) => x.cercleId == c.id && x.statut != 'annulee').toList();
  if (ici.isEmpty) return 1;
  final ouverts = ici.where((x) => x.statut != 'confirmee').map((x) => x.tour);
  if (ouverts.isNotEmpty) return ouverts.reduce(math.min);
  return ici.map((x) => x.tour).reduce(math.max) + 1;
}

/// La cagnotte qui m'arrive le plus tôt, toutes tontines confondues.
({ResumeCercle cercle, int dans})? _prochaineCagnotte(List<ResumeCercle> cercles, Map<String, int> tours) {
  ({ResumeCercle cercle, int dans})? meilleure;
  for (final c in cercles) {
    final t = tours[c.id] ?? 0;
    final place = c.maPlace;
    if (place == null || t < 1 || t > c.nombreMembresCible || place < t) continue;
    final dans = place - t;
    if (meilleure == null || dans < meilleure.dans) meilleure = (cercle: c, dans: dans);
  }
  return meilleure;
}

String _phraseCagnotte(({ResumeCercle cercle, int dans}) p) {
  final montant = '${formatAmount(p.cercle.reglement.montant * p.cercle.nombreMembresCible)} FCFA';
  return switch (p.dans) {
    0 => 'C’est ton tour : tu reçois $montant',
    1 => 'Ta cagnotte au prochain tour : $montant',
    final n => 'Ta cagnotte dans $n tours : $montant',
  };
}

/// Une tontine dans le carrousel : son cercle des tours, le montant, où elle en est pour moi.
class _CarteTontine extends StatelessWidget {
  const _CarteTontine({required this.cercle, required this.tour, required this.onTap, this.aPayer});

  final ResumeCercle cercle;
  final int tour;
  final Cotisation? aPayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = cercle;
    final n = c.nombreMembresCible;
    final place = c.maPlace;
    final demarre = tour >= 1 && tour <= n;
    final (String situation, Color couleur) = switch (c.statut) {
      _ when aPayer != null => ('À payer avant le ${formatDate(aPayer!.dateLimite)}', AppColors.orange),
      'en_attente' => ('Cherche des membres : ${c.nombreInscrits} sur $n', AppColors.textMuted),
      'termine' => ('Terminée', AppColors.textMuted),
      _ when demarre && place != null && place == tour => ('Tu reçois à ce tour', AppColors.green),
      _ when demarre && place != null && place > tour => ('Tu reçois au tour $place', AppColors.textMuted),
      _ when place != null => ('Tu as reçu au tour $place', AppColors.textMuted),
      _ => ('À jour', AppColors.textMuted),
    };
    final centre = c.statut == 'termine'
        ? const Icon(Icons.check, size: 22, color: AppColors.darkGreen)
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              demarre ? '$tour/$n' : '${c.nombreInscrits}/$n',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.1),
            ),
            Text(demarre ? 'tour' : 'places', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]);
    return SizedBox(
      width: 236,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Espace.ecran),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CercleDesTours(
                  membres: n,
                  tourEnCours: tour,
                  maPlace: place,
                  inscrits: c.nombreInscrits,
                  taille: 100,
                  centre: centre,
                ),
                const Spacer(),
                if (c.organisateur)
                  const Tooltip(
                    message: 'Tu l’organises',
                    child: Icon(Icons.star_outline_rounded, size: 20, color: AppColors.textMuted),
                  ),
              ],
            ),
            const Spacer(),
            Text.rich(TextSpan(children: [
              TextSpan(
                text: formatAmount(c.reglement.montant),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.1),
              ),
              const TextSpan(text: ' FCFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ])),
            const SizedBox(height: 2),
            Text(
              '${c.frequence == 'hebdomadaire' ? 'chaque semaine' : c.frequence == 'mensuelle' ? 'chaque mois' : 'tous les ${c.reglement.periodeJours} jours'} · $n membres',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: Espace.sm),
            Text(
              situation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: couleur),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nom});

  final String nom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                () {
                  final n = DateTime.now();
                  return '${_jours[n.weekday - 1]} ${n.day} ${_mois[n.month - 1]}';
                }(),
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              Text(
                nom.isEmpty ? 'Bonjour.' : 'Bonjour, ${nom.split(' ').first}.',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.prochaine,
    required this.tourDe,
    required this.total,
    required this.tontines,
    required this.aPayer,
    required this.enPreparation,
  });

  final ({ResumeCercle cercle, int dans})? prochaine;
  final Map<String, int> tourDe;
  final int total;
  final int tontines;
  final int aPayer;
  final int enPreparation;

  @override
  Widget build(BuildContext context) {
    final p = prochaine;
    return Container(
      padding: const EdgeInsets.all(Espace.ecran),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(Rayon.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.white70,
              ),
              SizedBox(width: Espace.sm),
              Text(
                'Total de mes cotisations confirmées',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: Espace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatAmount(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: '  FCFA',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (p != null)
                CercleDesTours(
                  membres: p.cercle.nombreMembresCible,
                  tourEnCours: tourDe[p.cercle.id] ?? 0,
                  maPlace: p.cercle.maPlace,
                  taille: 72,
                  surFonce: true,
                ),
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: Espace.sm),
            Text(
              _phraseCagnotte(p),
              style: const TextStyle(color: AppColors.lime, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: Espace.base),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: Espace.base),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Tontines', value: '$tontines')),
              Expanded(child: _Stat(label: 'À payer', value: '$aPayer')),
              Expanded(child: _Stat(label: 'En préparation', value: '$enPreparation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: Espace.xs),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add,
            label: 'Créer',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateTontineScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: Espace.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.search,
            label: 'Trouver',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CerclesCatalogScreen()),
            ),
          ),
        ),
        const SizedBox(width: Espace.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.vpn_key_outlined,
            label: "J'ai un code",
            onTap: () => _codeInvitation(context),
          ),
        ),
      ],
    );
  }
}

/// Le SMS d'invitation contient le code de la tontine (son identifiant).
Future<void> _codeInvitation(BuildContext context) async {
  final ctrl = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Code d’invitation'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: 'Colle le code reçu par SMS'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Voir la tontine')),
      ],
    ),
  );
  final id = RegExp(r'[0-9a-fA-F-]{36}').firstMatch(code ?? '')?.group(0);
  if (id == null) {
    if (code != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code non reconnu.')));
    }
    return;
  }
  if (context.mounted) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CercleDetailsScreen(cercleId: id)));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: Espace.base, horizontal: Espace.sm),
      child: Column(
        children: [
          Icon(icon, color: AppColors.green, size: 24),
          const SizedBox(height: Espace.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentsBanner extends StatelessWidget {
  const _PendingPaymentsBanner({required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rayon.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CotisationsListScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Espace.base),
          child: Row(
            children: [
              const Icon(Icons.south_west, color: AppColors.orange, size: 24),
              const SizedBox(width: Espace.iconeTexte),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre == 1 ? '1 paiement à confirmer' : '$nombre paiements à confirmer',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'On t’a déclaré un paiement : confirme ce que tu as reçu.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextContributionCard extends StatelessWidget {
  const _NextContributionCard({required this.cotisation, required this.nomCercle});

  final Cotisation cotisation;
  final String nomCercle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Espace.ecran),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(Rayon.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.schedule, size: 16, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ta cotisation · $nomCercle · tour ${cotisation.tour}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAmount(cotisation.montant),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: '  FCFA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StatusBadge(
            label: 'À payer avant le ${formatDate(cotisation.dateLimite)}',
            foreground: AppColors.lime,
          ),
          const SizedBox(height: Espace.ecran),
          AppButton(
            label: 'Déclarer mon paiement',
            background: AppColors.lime,
            foreground: AppColors.darkGreen,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentDeclareScreen(cotisationId: cotisation.id, cotisation: cotisation),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.white54),
              SizedBox(width: 6),
              Text(
                'Inscrit au registre après confirmation',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}