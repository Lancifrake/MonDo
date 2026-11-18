import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sobre.dart';

/// Ma boîte de notifications (GET /notifications). Une notification non lue est en encre,
/// une notification lue en gris ; la toucher la marque comme lue.
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
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          if (nonLues > 0)
            TextButton(onPressed: () => faire(service.marquerToutesCommeLues), child: const Text('Tout marquer lu')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meNotificationsRefreshableProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: selon(notifications, (liste) {
            if (liste.isEmpty) return const [Note('Aucune alerte pour l’instant.')];
            return [
              Bloc(enfants: [
                for (final n in liste)
                  InkWell(
                    onTap: n.lue ? null : () => faire(() => service.marquerCommeLue(n.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          n.texte,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: n.lue ? FontWeight.w400 : FontWeight.w600,
                            color: n.lue ? AppColors.textMuted : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateCourte(n.creeeLe)}${n.lue ? '' : ' · non lue'}',
                          style: styleStatut(n.lue ? Ton.gris : Ton.action).copyWith(fontWeight: FontWeight.w400),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ];
          }, reessayer: () => ref.invalidate(meNotificationsRefreshableProvider)),
        ),
      ),
    );
  }
}
