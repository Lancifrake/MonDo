import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sobre.dart';

/// Ma boîte de notifications (GET /notifications). Une alerte non lue a son intitulé en gras, sa date en vert
/// et un point vert ; la toucher la marque comme lue.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(meNotificationsRefreshableProvider);
    final service = ref.read(notificationsServiceProvider);

    Future<void> faire(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(meNotificationsRefreshableProvider);
      } catch (e) {
        if (context.mounted) afficherErreur(context, e);
      }
    }

    final nonLues = notifications.valueOrNull?.where((n) => !n.lue).length ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alertes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (nonLues > 0)
            TextButton(onPressed: () => faire(service.marquerToutesCommeLues), child: const Text('Tout marquer lu')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meNotificationsRefreshableProvider),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: selon(notifications, (liste) {
            if (liste.isEmpty) {
              return const [Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Note('Aucune alerte pour l’instant.'))];
            }
            return [
              for (var i = 0; i < liste.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, indent: 70, color: AppColors.border),
                _Alerte(
                  texte: liste[i].texte,
                  date: dateCourte(liste[i].creeeLe),
                  lue: liste[i].lue,
                  onTap: liste[i].lue ? null : () => faire(() => service.marquerCommeLue(liste[i].id)),
                ),
              ],
            ];
          }, reessayer: () => ref.invalidate(meNotificationsRefreshableProvider)),
        ),
      ),
    );
  }
}

/// Le serveur n'envoie qu'un texte : la catégorie (icône et intitulé) se déduit de ses mots.
({IconData icone, String titre, bool urgent}) _categorie(String t) {
  final m = t.toLowerCase();
  bool a(String mot) => m.contains(mot);
  if (a('mise en demeure')) return (icone: Icons.report_outlined, titre: 'Mise en demeure', urgent: true);
  if (a('litige')) return (icone: Icons.gavel_outlined, titre: 'Litige', urgent: false);
  if (a('en retard')) return (icone: Icons.schedule, titre: 'Paiement en retard', urgent: true);
  if (a('rappel')) return (icone: Icons.event_outlined, titre: 'Rappel d’échéance', urgent: false);
  if (a('récupération') || a('bloqué') || a('débloqué')) {
    return (icone: Icons.phonelink_lock_outlined, titre: 'Sécurité du compte', urgent: a('si ce n'));
  }
  if (a('identité')) return (icone: Icons.verified_user_outlined, titre: 'Vérification d’identité', urgent: false);
  if (a('parrain')) return (icone: Icons.group_add_outlined, titre: 'Parrainage', urgent: false);
  if (a('contact de confiance')) return (icone: Icons.contact_phone_outlined, titre: 'Contact de confiance', urgent: false);
  if (a('échange')) return (icone: Icons.swap_horiz, titre: 'Échange de place', urgent: false);
  if (a('frais de place') || a('perd sa place') || a('quitté')) {
    return (icone: Icons.person_remove_outlined, titre: 'Départ d’un membre', urgent: false);
  }
  if (a('payé') || a('paiement') || a('envoyés') || a('confirmée')) {
    return (icone: Icons.payments_outlined, titre: 'Paiement', urgent: a('échoué'));
  }
  if (a('invite') || a('cycle') || a('cercle')) return (icone: Icons.groups_outlined, titre: 'Ta tontine', urgent: false);
  return (icone: Icons.notifications_none, titre: 'MonDo', urgent: false);
}

/// Une alerte, à la manière du profil : icône à gauche, intitulé et date, message en dessous.
class _Alerte extends StatelessWidget {
  const _Alerte({required this.texte, required this.date, required this.lue, this.onTap});

  final String texte;
  final String date;
  final bool lue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = _categorie(texte);
    final brut = texte.replaceFirst(RegExp(r'^MonDo\s*:\s*'), '');
    final message = brut.isEmpty ? brut : brut[0].toUpperCase() + brut.substring(1);
    final couleurIcone = c.urgent ? AppColors.orange : (lue ? AppColors.textMuted : AppColors.green);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(c.icone, size: 24, color: couleurIcone)),
          const SizedBox(width: 26),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    c.titre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: lue ? FontWeight.w400 : FontWeight.w600,
                      color: c.urgent && !lue ? AppColors.orange : AppColors.textDark,
                    ),
                  ),
                ),
                Text(date, style: TextStyle(fontSize: 12.5, color: lue ? AppColors.textMuted : AppColors.green)),
                if (!lue) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.textMuted),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
