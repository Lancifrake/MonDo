import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mise_a_jour.dart';
import '../theme/app_colors.dart';
import 'disputes/disputes_list_screen.dart';
import 'home_screen.dart';
import 'cotisations/cotisations_list_screen.dart';
import 'notifications/notifications_screen.dart';
import 'compte/profil_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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

  @override
  Widget build(BuildContext context) {
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              label: 'Cotisations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel_outlined),
              label: 'Litiges',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              label: 'Alertes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
