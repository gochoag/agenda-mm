import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../services/month_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'cover_editor_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
      UpdateService.instance.checkAndPromptUpdate(context);
      _loadVersion();
    });
  }

  Future<void> _loadVersion() async {
    final info = await UpdateService.instance.getPackageInfo();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version}+${info.buildNumber}';
      });
    }
  }

  User? get user => ApiService.instance.currentUser;

  List<Widget> get _screens {
    final screens = <Widget>[
      const NotesScreen(),
      const CalendarScreen(),
    ];
    if (user?.isAdmin == true) {
      screens.add(const AdminScreen());
    }
    return screens;
  }

  Future<void> _logout() async {
    final confirm = await AppDialogs.confirmAction(
      context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas salir de tu cuenta?',
      confirmText: 'Cerrar Sesión',
      isDestructive: true,
      icon: Icons.logout,
    );

    if (confirm) {
      await ApiService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: const Color(0xFFFFF59D), // Color amarillo post-it suave
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt, color: AppColors.primary),
            label: 'Notas Adhesivas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: AppColors.primary),
            label: 'Calendario',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.primary),
              label: 'Administración',
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFFFFF59D),
                child: Text(
                  (user?.username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              accountName: Text(
                user?.username ?? 'Usuario',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                'Rol: ${user?.role.toUpperCase() ?? "INVITADO"}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Notas Adhesivas'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Calendario'),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Administración (Backup & Passwords)'),
                selected: _currentIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brush_rounded, color: Color(0xFFD97706)),
              title: const Text('Carátula del Mes (Canva)'),
              subtitle: const Text('Diseña tu portada estilo libreta', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoverEditorScreen(
                      monthYear: MonthStateService.instance.activeMonthYearString,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.system_update_alt_rounded, color: AppColors.accent),
              title: const Text('Buscar Actualizaciones'),
              subtitle: _appVersion.isNotEmpty
                  ? Text('Versión instalada: $_appVersion', style: const TextStyle(fontSize: 12))
                  : null,
              onTap: () {
                Navigator.pop(context);
                UpdateService.instance.checkAndPromptUpdate(context, isManual: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            if (_appVersion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Agenda MM • $_appVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
