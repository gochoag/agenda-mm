import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../models/app_version.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final AppVersionInfo versionInfo;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.currentVersion,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  int _progress = 0;
  String? _statusText;
  String? _errorMessage;

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0;
      _statusText = 'Iniciando descarga...';
    });

    try {
      OtaUpdate()
          .execute(
        widget.versionInfo.downloadUrl,
        destinationFilename: 'agenda_update_${widget.versionInfo.versionCode}.apk',
      )
          .listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final parsed = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _progress = parsed;
                _statusText = 'Descargando: $_progress%';
              });
              break;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              setState(() {
                _progress = 100;
                _statusText = 'Abriendo instalador del sistema...';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'Ya hay una descarga en proceso.';
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage =
                    'Se requiere permiso para instalar aplicaciones desde esta app. Concédelo en ajustes de Android.';
              });
              break;
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'Error al procesar la actualización: ${event.value ?? "Error inesperado"}';
              });
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Ocurrió un error al descargar: $err';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = 'No se pudo iniciar la actualización: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.versionInfo;

    return PopScope(
      canPop: !info.forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con Icono
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 38,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              const Text(
                '¡Actualización Disponible!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Comparación de versiones
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v${widget.currentVersion}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                      ),
                      Text(
                        'v${info.versionName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notas de la versión
              if (info.releaseNotes.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Qué hay de nuevo?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.releaseNotes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Mensaje de seguridad
              const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tus notas, eventos y sesión se mantendrán intactos.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Estado de descarga o Error
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress / 100 : null,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusText ?? 'Descargando...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'El instalador de Android se abrirá automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Reintentar descarga'),
                ),
              ] else ...[
                // Botones de acción principales
                ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Actualizar ahora',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!info.forceUpdate) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Recordar más tarde',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
