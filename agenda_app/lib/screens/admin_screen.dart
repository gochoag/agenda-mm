import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<User> _users = [];
  bool _isLoadingUsers = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await ApiService.instance.getAdminUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        AppSnackBar.show(context, 'Error al obtener usuarios: $e', isError: true);
      }
    }
  }

  Future<void> _openChangePasswordDialog(User targetUser) async {
    final passController = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Cambiar Contraseña: ${targetUser.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa la nueva contraseña para el usuario "${targetUser.username}" (${targetUser.role}):',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPass = passController.text.trim();
                if (newPass.length < 4) {
                  AppSnackBar.show(context, 'Mínimo 4 caracteres requeridos', isError: true);
                  return;
                }

                Navigator.pop(dialogCtx);

                try {
                  await ApiService.instance.changeUserPassword(targetUser.id, newPass);
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      'Contraseña de ${targetUser.username} actualizada con éxito',
                      isSuccess: true,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      'Error al cambiar contraseña: $e',
                      isError: true,
                    );
                  }
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateCoadminDialog() async {
    final userController = TextEditingController();
    final passController = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo CoAdmin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'El CoAdmin podrá acceder a sus propias notas adhesivas y calendario.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña (mínimo 4 caracteres)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uname = userController.text.trim();
                final pass = passController.text.trim();

                if (uname.isEmpty || pass.length < 4) {
                  AppSnackBar.show(
                    context,
                    'Completa el usuario y una clave de al menos 4 caracteres',
                    isError: true,
                  );
                  return;
                }

                Navigator.pop(dialogCtx);

                try {
                  await ApiService.instance.createAdminUser(username: uname, password: pass, role: 'coadmin');
                  _loadUsers();
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      'CoAdmin "$uname" creado con éxito',
                      isSuccess: true,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      'Error al crear CoAdmin: $e',
                      isError: true,
                    );
                  }
                }
              },
              child: const Text('Crear CoAdmin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(User targetUser) async {
    final ok = await AppDialogs.confirmAction(
      context,
      title: '¿Eliminar usuario ${targetUser.username}?',
      message: 'Esta acción eliminará al usuario y todas sus notas y eventos asociados de forma definitiva.',
      confirmText: 'Eliminar',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );

    if (ok) {
      try {
        await ApiService.instance.deleteAdminUser(targetUser.id);
        _loadUsers();
        if (mounted) {
          AppSnackBar.show(
            context,
            'Usuario "${targetUser.username}" eliminado',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(
            context,
            'Error al eliminar usuario: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final rawJson = await ApiService.instance.getAdminBackupRawJson();
      final dateTag = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'agenda_backup_$dateTag.json';

      // Guardar en archivo temporal para compartir/descargar
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(rawJson);

      setState(() => _isBackingUp = false);

      // Usar share_plus para guardar o enviar por cualquier app
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
        ),
      );

      if (mounted) {
        AppSnackBar.show(
          context,
          'Copia de seguridad generada: $filename',
          isSuccess: true,
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        AppSnackBar.show(
          context,
          'Error al generar respaldo: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isEmpty) return;

      final path = result.first.path;
      if (path == null) {
        throw Exception('No se pudo acceder a la ruta del archivo seleccionado');
      }

      final file = File(path);
      final jsonContent = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonContent);

      final usersCount = (backupData['users'] as List?)?.length ?? 0;
      final eventsCount = (backupData['calendar_events'] as List?)?.length ?? 0;
      final notesCount = (backupData['sticky_notes'] as List?)?.length ?? 0;

      if (!mounted) return;

      // Diálogo de Advertencia y Confirmación Explícita
      final confirmed = await AppDialogs.confirmAction(
        context,
        title: 'Restauración Limpia',
        message: '¡ATENCIÓN! La restauración reemplazará por completo la base de datos actual.\n\n'
            'Datos encontrados en el archivo seleccionado:\n'
            '• Usuarios: $usersCount\n'
            '• Eventos de calendario: $eventsCount\n'
            '• Notas adhesivas: $notesCount\n\n'
            '¿Deseas proceder con el restablecimiento?',
        confirmText: 'RESTAURAR AHORA',
        isDestructive: true,
        icon: Icons.warning_amber_rounded,
      );

      if (!confirmed) return;

      setState(() => _isRestoring = true);

      final res = await ApiService.instance.restoreAdminBackup(backupData);

      setState(() => _isRestoring = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Restauración Exitosa'),
            content: Text(
              'La base de datos se restauró limpiamente.\n\n'
              '${res["message"] ?? "Proceso finalizado."}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadUsers();
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isRestoring = false);
      if (mounted) {
        AppSnackBar.show(
          context,
          'Error en restauración: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. SECCIÓN DE USUARIOS Y CONTRASEÑAS
          _buildSectionCard(
            title: 'Gestión de Usuarios y Contraseñas',
            subtitle: 'Crea CoAdmins, cambia contraseñas y administra accesos',
            icon: Icons.manage_accounts_outlined,
            child: _isLoadingUsers
                ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Crear Nuevo CoAdmin'),
                        onPressed: _openCreateCoadminDialog,
                      ),
                      const SizedBox(height: 14),
                      ..._users.map((u) {
                        final isAdmin = u.role == 'admin';
                        final isMe = u.id == ApiService.instance.currentUser?.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? AppColors.primary : AppColors.accent,
                              foregroundColor: Colors.white,
                              child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
                            ),
                            title: Text(
                              u.username,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Rol: ${u.role}${isMe ? " (Tú)" : ""}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.vpn_key_outlined, size: 20),
                                  tooltip: 'Cambiar Contraseña',
                                  onPressed: () => _openChangePasswordDialog(u),
                                ),
                                if (!isMe)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    tooltip: 'Eliminar CoAdmin',
                                    onPressed: () => _confirmDeleteUser(u),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // 2. COPIA DE SEGURIDAD (BACKUP .JSON)
          _buildSectionCard(
            title: 'Copia de Seguridad (.JSON)',
            subtitle: 'Exporta todos los usuarios, notas y calendario en un solo archivo JSON',
            icon: Icons.cloud_download_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Este archivo te permite salvar toda la información si cambias de servidor o para guardar copias periódicas.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isBackingUp ? null : _handleBackup,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isBackingUp ? 'Exportando...' : 'Descargar Copia de Seguridad (.JSON)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. RESTAURACIÓN LIMPIA (.JSON)
          _buildSectionCard(
            title: 'Restauración Limpia (.JSON)',
            subtitle: 'Restaura todos los datos desde un archivo de respaldo previo',
            icon: Icons.restore_page_outlined,
            iconColor: Colors.orange.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La restauración limpia vacía la base de datos actual para evitar duplicados e inserta la información del JSON exactamente como fue respaldada.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isRestoring ? null : _handleRestore,
                  icon: _isRestoring
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red.shade800),
                        )
                      : const Icon(Icons.file_upload_outlined),
                  label: Text(_isRestoring ? 'Restaurando base de datos...' : 'Cargar Archivo .JSON y Restaurar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
