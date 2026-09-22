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

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      versionCode: (json['version_code'] as num?)?.toInt() ?? 1,
      versionName: json['version_name'] as String? ?? '1.0.0',
      minSupportedVersionCode: (json['min_supported_version_code'] as num?)?.toInt() ?? 1,
      forceUpdate: json['force_update'] as bool? ?? false,
      releaseNotes: json['release_notes'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      apkAvailable: json['apk_available'] as bool? ?? false,
    );
  }
}
