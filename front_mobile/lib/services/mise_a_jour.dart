import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Une version de l'application plus récente que celle installée, publiée sur GitHub.
class NouvelleVersion {
  const NouvelleVersion({required this.version, required this.build, required this.lienApk, required this.notes});

  final String version;
  final int build;
  final String lienApk;
  final String notes;
}

/// Dépôt public où chaque version Android est publiée : une release au tag « mobile-v1.0.1+2 », avec l'APK attaché
/// (voir scripts/publier-version.sh).
const _releases = 'https://api.github.com/repos/Lancifrake/MonDo/releases?per_page=20';
final _tag = RegExp(r'^mobile-v(\d+\.\d+\.\d+)\+(\d+)$');

/// Lit la liste des releases GitHub et rend la plus récente version mobile si son numéro de build dépasse
/// `buildActuel`. Les brouillons, préversions, autres tags et releases sans APK sont ignorés.
NouvelleVersion? versionPlusRecente(List<dynamic> releases, int buildActuel) {
  NouvelleVersion? meilleure;
  for (final r in releases.whereType<Map<String, dynamic>>()) {
    if (r['draft'] == true || r['prerelease'] == true) continue;
    final m = _tag.firstMatch('${r['tag_name']}');
    if (m == null) continue;
    final build = int.parse(m.group(2)!);
    final apk = (r['assets'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((a) => '${a['browser_download_url']}')
        .where((u) => u.endsWith('.apk'))
        .firstOrNull;
    if (apk == null || build <= buildActuel || (meilleure != null && build <= meilleure.build)) continue;
    meilleure = NouvelleVersion(version: m.group(1)!, build: build, lienApk: apk, notes: '${r['body'] ?? ''}'.trim());
  }
  return meilleure;
}

/// Au démarrage, sur Android seulement (iPhone : TestFlight). Silencieux en cas d'erreur réseau : la mise à jour
/// n'empêche jamais d'utiliser l'application.
Future<NouvelleVersion?> chercherMiseAJour() async {
  if (!Platform.isAndroid) return null;
  try {
    final info = await PackageInfo.fromPlatform();
    final actuel = int.tryParse(info.buildNumber) ?? 0;
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 6)));
    final r = await dio.get<List<dynamic>>(_releases, options: Options(headers: {'Accept': 'application/vnd.github+json'}));
    return versionPlusRecente(r.data ?? const [], actuel);
  } catch (_) {
    return null;
  }
}
