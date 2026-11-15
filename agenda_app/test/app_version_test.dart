import 'package:agenda_app/models/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee versionCode, nombre y APK de un GitHub Release', () {
    final info = AppVersionInfo.fromGithubRelease({
      'tag_name': 'build-7',
      'name': 'v1.0.7',
      'body': 'Notas',
      'assets': [
        {'name': 'otro.txt', 'browser_download_url': 'https://x/otro.txt'},
        {'name': 'agenda-mm.apk', 'browser_download_url': 'https://x/agenda-mm.apk'},
      ],
    });
    expect(info.versionCode, 7);
    expect(info.versionName, '1.0.7');
    expect(info.downloadUrl, 'https://x/agenda-mm.apk');
    expect(info.releaseNotes, 'Notas');
  });

  test('sin APK o con tag inválido nunca ofrece actualización', () {
    expect(AppVersionInfo.fromGithubRelease({'tag_name': 'build-9', 'assets': []}).versionCode, 0);
    expect(
      AppVersionInfo.fromGithubRelease({
        'tag_name': 'otra-cosa',
        'assets': [{'name': 'a.apk', 'browser_download_url': 'https://x/a.apk'}],
      }).versionCode,
      0,
    );
  });
}
