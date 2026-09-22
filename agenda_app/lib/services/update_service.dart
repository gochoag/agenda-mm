import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';
import '../services/api_service.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  PackageInfo? _cachedPackageInfo;

  Future<PackageInfo> getPackageInfo() async {
    _cachedPackageInfo ??= await PackageInfo.fromPlatform();
    return _cachedPackageInfo!;
  }

  /// Verifica si el servidor tiene un versionCode mayor que el instalado
  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      final info = await getPackageInfo();
      final currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;

      final serverVersion = await ApiService.instance.checkAppVersion();
      if (serverVersion == null) return null;

      // Si el servidor tiene un número de compilación superior, hay actualización disponible
      if (serverVersion.versionCode > currentBuildNumber) {
        return serverVersion;
      }
    } catch (e) {
      debugPrint('Error al verificar actualización: $e');
    }
    return null;
  }

  /// Ejecuta la verificación y levanta el diálogo si hay una nueva versión
  Future<void> checkAndPromptUpdate(BuildContext context, {bool isManual = false}) async {
    try {
      final info = await getPackageInfo();
      final updateInfo = await checkForUpdate();

      if (!context.mounted) return;

      if (updateInfo != null) {
        showDialog(
          context: context,
          barrierDismissible: !updateInfo.forceUpdate,
          builder: (dialogCtx) => UpdateDialog(
            versionInfo: updateInfo,
            currentVersion: info.version,
          ),
        );
      } else if (isManual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tu aplicación está al día (v${info.version}).'),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (isManual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo verificar la actualización en este momento.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
