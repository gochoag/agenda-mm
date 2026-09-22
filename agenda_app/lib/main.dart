import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/cover_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación en vertical exclusivamente
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar variables de entorno desde .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Advertencia: No se pudo cargar .env: $e");
  }

  // Inicializar localización de fechas en español
  try {
    await initializeDateFormatting('es_ES', null);
  } catch (_) {}

  // Inicializar API Service (lee token de SharedPreferences)
  await ApiService.instance.init();

  runApp(const AgendaApp());

  // Inicializar notificaciones y timezone en segundo plano sin congelar el arranque
  NotificationService.instance.init();
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda MM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ApiService.instance.isAuthenticated
          ? const CoverSplashScreen()
          : const LoginScreen(),
    );
  }
}
