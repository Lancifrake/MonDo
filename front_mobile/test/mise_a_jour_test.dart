import 'package:flutter_test/flutter_test.dart';
import 'package:mon_do/services/mise_a_jour.dart';

Map<String, dynamic> release(String tag, {bool apk = true, bool draft = false, String body = ''}) => {
      'tag_name': tag,
      'draft': draft,
      'prerelease': false,
      'body': body,
      'assets': [
        if (apk) {'browser_download_url': 'https://github.com/Lancifrake/MonDo/releases/download/$tag/MonDo.apk'},
      ],
    };

void main() {
  test('propose la version mobile la plus récente, si elle dépasse celle installée', () {
    final v = versionPlusRecente([
      release('mobile-v1.0.2+3', body: 'Nouveaux écrans'),
      release('mobile-v1.0.1+2'),
      release('v2.0.0'),
    ], 1)!;
    expect(v.version, '1.0.2');
    expect(v.build, 3);
    expect(v.notes, 'Nouveaux écrans');
    expect(v.lienApk, endsWith('mobile-v1.0.2+3/MonDo.apk'));
  });

  test('rien si la version installée est déjà la dernière', () {
    expect(versionPlusRecente([release('mobile-v1.0.1+2')], 2), isNull);
  });

  test('ignore les brouillons, les tags étrangers et les releases sans APK', () {
    expect(
      versionPlusRecente([
        release('mobile-v1.0.5+9', draft: true),
        release('mobile-v1.0.4+8', apk: false),
        release('serveur-v3'),
      ], 1),
      isNull,
    );
  });
}
