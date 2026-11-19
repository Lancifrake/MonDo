import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/api_client_provider.dart';
import '../providers/cotisations_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/mise_a_jour.dart';
import '../theme/app_colors.dart';
import 'disputes/disputes_list_screen.dart';
import 'home_screen.dart';
import 'cotisations/cotisations_list_screen.dart';
import 'notifications/notifications_screen.dart';
import 'compte/profil_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Une nouvelle version publiée ? On le propose une fois par ouverture, sans bloquer.
    chercherMiseAJour().then((v) {
      if (v != null && mounted) _proposerMiseAJour(v);
    });
  }

  Future<void> _proposerMiseAJour(NouvelleVersion v) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Nouvelle version ${v.version}'),
          content: Text(
            '${v.notes.isEmpty ? 'Une nouvelle version de MonDo est disponible.' : v.notes}\n\n'
            'Le téléchargement s’ouvre dans le navigateur ; installe ensuite le fichier. Tes tontines et ton compte restent intacts.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse(v.lienApk), mode: LaunchMode.externalApplication);
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      );

  // Écrans branchés au serveur (requêtes signées)
  static const _pages = <Widget>[
    HomeScreen(),
    CotisationsListScreen(),
    DisputesListScreen(),
    NotificationsScreen(),
    ProfilScreen(),
  ];

  /// Icône d'onglet : contour au repos, pleine quand l'onglet est actif, pastille du nombre en attente.
  static BottomNavigationBarItem _onglet(IconData repos, IconData actif, String libelle, {int attente = 0}) {
    Widget icone(IconData i) => attente > 0
        ? Badge(
            label: Text(attente > 9 ? '9+' : '$attente'),
            backgroundColor: AppColors.orange,
            child: Icon(i),
          )
        : Icon(i);
    return BottomNavigationBarItem(
      icon: icone(repos),
      activeIcon: icone(actif),
      label: libelle,
      tooltip: attente > 0 ? '$libelle, $attente en attente' : libelle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final moi = ref.read(apiClientProvider).membreId;
    final cotisationsAFaire = ref
            .watch(mesCotisationsRefreshableProvider)
            .valueOrNull
            ?.where((c) => (c.payeurId == moi && c.statut == 'due') || (c.beneficiaireId == moi && c.statut == 'declaree'))
            .length ??
        0;
    final alertesNonLues = ref.watch(meNotificationsRefreshableProvider).valueOrNull?.where((n) => !n.lue).length ?? 0;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            _onglet(Icons.home_outlined, Icons.home, 'Accueil'),
            _onglet(Icons.payments_outlined, Icons.payments, 'Cotisations', attente: cotisationsAFaire),
            _onglet(Icons.gavel_outlined, Icons.gavel, 'Litiges'),
            _onglet(Icons.notifications_none, Icons.notifications, 'Alertes', attente: alertesNonLues),
            _onglet(Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }
}
