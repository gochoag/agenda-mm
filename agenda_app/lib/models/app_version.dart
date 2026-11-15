class AppVersionInfo {
  final int versionCode;
  final String versionName;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String releaseNotes;
  final String downloadUrl;
  final bool apkAvailable;

  const AppVersionInfo({
    required this.versionCode,
    required this.versionName,
    required this.minSupportedVersionCode,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.apkAvailable,
  });

  /// Lee la respuesta de `GET /repos/{repo}/releases/latest`. El tag es `build-N` (N = versionCode).
  factory AppVersionInfo.fromGithubRelease(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    final assets = (json['assets'] as List?) ?? const [];
    final apk = assets.cast<Map<String, dynamic>>().where(
          (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        );
    final downloadUrl = apk.isEmpty ? '' : apk.first['browser_download_url'] as String? ?? '';
    final name = (json['name'] as String? ?? '').replaceFirst(RegExp(r'^v'), '');

    return AppVersionInfo(
      // Sin tag válido o sin APK => versionCode 0: nunca se ofrece como actualización
      versionCode: downloadUrl.isEmpty ? 0 : int.tryParse(tag.replaceFirst('build-', '')) ?? 0,
      versionName: name.isEmpty ? tag : name,
      minSupportedVersionCode: 1,
      forceUpdate: false,
      releaseNotes: json['body'] as String? ?? '',
      downloadUrl: downloadUrl,
      apkAvailable: downloadUrl.isNotEmpty,
    );
  }
}
