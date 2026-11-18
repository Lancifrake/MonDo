import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart' show Tontine, Echeance, PaymentStatus;
import '../models/api_models.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cercles_provider.dart';
import '../providers/cotisations_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/echeance_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/tontine_card.dart';
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

    Future<void> rafraichir() async {
      ref.invalidate(mesCerclesRefreshableProvider);
      ref.invalidate(mesCotisationsRefreshableProvider);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: rafraichir,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _Header(nom: compte?.nom ?? ''),
            const SizedBox(height: 20),
            _BalanceCard(
              total: verse,
              tontines: cercles.length,
              aPayer: aPayer.length,
              enPreparation: cercles.where((c) => c.statut == 'en_attente').length,
            ),
            const SizedBox(height: 16),
            const _QuickActions(),
            if (aValider > 0) ...[
              const SizedBox(height: 16),
              _PendingPaymentsBanner(nombre: aValider),
            ],
            if (aPayer.isNotEmpty) ...[
              const SizedBox(height: 16),
              _NextContributionCard(cotisation: aPayer.first, nomCercle: nomDe[aPayer.first.cercleId] ?? 'ta tontine'),
            ],
            const SizedBox(height: 28),
            const _SectionTitle('Mes tontines'),
            const SizedBox(height: 12),
            if (cerclesAsync.isLoading && cercles.isEmpty) const LinearProgressIndicator(),
            if (cerclesAsync.hasError)
              Text(messageErreur(cerclesAsync.error!), style: const TextStyle(color: Colors.red)),
            if (!cerclesAsync.isLoading && cercles.isEmpty && !cerclesAsync.hasError)
              const Text(
                'Aucune tontine pour l’instant. Crées-en une ou trouve-en une ouverte.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            for (final c in cercles) ...[
              TontineCard(
                tontine: Tontine(
                  name: c.nom,
                  frequency: c.frequence == 'hebdomadaire' ? 'Chaque semaine' : 'Chaque mois',
                  members: c.nombreInscrits,
                  totalMembers: c.nombreMembresCible,
                  amount: c.reglement.montant,
                  status: aPayer.any((x) => x.cercleId == c.id) ? PaymentStatus.aPayer : PaymentStatus.aJour,
                  isTreasurer: c.organisateur,
                  progress: c.nombreMembresCible == 0 ? 0 : c.nombreInscrits / c.nombreMembresCible,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CercleDetailsScreen(cercleId: c.id)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (aPayer.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionTitle('Prochaines échéances'),
              const SizedBox(height: 12),
              for (final e in aPayer.take(5)) ...[
                EcheanceCard(
                  echeance: Echeance(
                    day: DateTime.parse(e.dateLimite).toLocal().day.toString().padLeft(2, '0'),
                    month: _mois[DateTime.parse(e.dateLimite).toLocal().month - 1],
                    title: nomDe[e.cercleId] ?? 'Tontine',
                    subtitle: 'Tour ${e.tour} · ${formatAmount(e.montant)} FCFA',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.nom});

  final String nom;

  String get _initiales {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    return mots.take(2).map((m) => m[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.pinkBg,
          child: Text(
            _initiales,
            style: const TextStyle(
              color: AppColors.pinkText,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
    required this.total,
    required this.tontines,
    required this.aPayer,
    required this.enPreparation,
  });

  final int total;
  final int tontines;
  final int aPayer;
  final int enPreparation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(22),
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
              SizedBox(width: 8),
              Text(
                'Total de mes cotisations confirmées',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAmount(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
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
        const SizedBox(width: 12),
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
      ],
    );
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.green),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
      color: AppColors.limeSoft,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CotisationsListScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre == 1 ? '1 paiement à valider' : '$nombre paiements à valider',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'À toi de confirmer la réception (onglet Cotisations, « Déclarée »)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(22),
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
                    fontWeight: FontWeight.w800,
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
            background: AppColors.amberBg,
            foreground: AppColors.amberText,
          ),
          const SizedBox(height: 18),
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