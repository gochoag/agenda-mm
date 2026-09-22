import 'package:flutter/material.dart';
import '../models/monthly_cover.dart';
import '../services/api_service.dart';
import '../services/month_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cover_card_view.dart';
import 'cover_editor_screen.dart';
import 'main_shell.dart';

class CoverSplashScreen extends StatefulWidget {
  const CoverSplashScreen({super.key});

  @override
  State<CoverSplashScreen> createState() => _CoverSplashScreenState();
}

class _CoverSplashScreenState extends State<CoverSplashScreen> with SingleTickerProviderStateMixin {
  MonthlyCover? _currentCover;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _initFlow();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initFlow() async {
    await MonthStateService.instance.init();
    final coverMonth = MonthStateService.instance.activeMonthYearString;

    try {
      final cover = await ApiService.instance.getMonthlyCover(coverMonth);
      if (mounted) {
        setState(() {
          _currentCover = cover;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      // Fallback si no hay conexión
      if (mounted) {
        _enterMainApp();
        return;
      }
    }

    // Esperar a que se aprecie la carátula de inicio
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Verificar si es un mes nuevo sin carátula personalizada
    final shouldPrompt = await MonthStateService.instance.shouldPromptNewMonthCover();
    if (shouldPrompt && mounted) {
      _showNewMonthPrompt();
    } else if (mounted) {
      _enterMainApp();
    }
  }

  void _enterMainApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showNewMonthPrompt() {
    final monthName = MonthStateService.instance.formattedActiveMonthName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF59D), // Amarillo post-it
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 36,
                  color: Color(0xFF854D0E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Bienvenido a $monthName!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Comienza un nuevo mes en tu libreta. ¿Deseas diseñar la carátula personalizada en el Canva o prefieres usar la carátula predeterminada?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoverEditorScreen(
                        monthYear: MonthStateService.instance.currentRealMonthYearString,
                        initialCover: _currentCover,
                      ),
                    ),
                  );
                  await MonthStateService.instance.markCurrentMonthHandled();
                  _enterMainApp();
                },
                icon: const Icon(Icons.brush_rounded, size: 18),
                label: const Text('Diseñar Carátula Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await MonthStateService.instance.markCurrentMonthHandled();
                  if (ctx.mounted) Navigator.pop(ctx);
                  _enterMainApp();
                },
                child: const Text(
                  'Omitir por ahora (Usar Carátula Default)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFDF7),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Fondo oscuro elegante para resaltar la libreta
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.68,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CoverCardView(
                            cover: _currentCover!,
                            showSpiral: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _enterMainApp,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 18),
                      label: const Text(
                        'Abrir Agenda',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
