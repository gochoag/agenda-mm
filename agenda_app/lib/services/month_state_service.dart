import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MonthStateService {
  static final MonthStateService instance = MonthStateService._internal();
  MonthStateService._internal();

  static const String _keyLastVisitedMonth = 'last_visited_month_v1';
  static const String _keySelectedCoverMonth = 'selected_display_cover_month_v1';

  late final ValueNotifier<DateTime> activeMonthNotifier = ValueNotifier<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month),
  );

  DateTime get activeMonth => activeMonthNotifier.value;

  String get activeMonthYearString => DateFormat('yyyy-MM').format(activeMonth);

  String get currentRealMonthYearString => DateFormat('yyyy-MM').format(DateTime.now());

  bool get isViewingCurrentMonth => activeMonthYearString == currentRealMonthYearString;

  String get formattedActiveMonthName {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[activeMonth.month - 1]} ${activeMonth.year}';
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMonth = prefs.getString(_keySelectedCoverMonth);
      if (savedMonth != null && savedMonth.contains('-')) {
        final parts = savedMonth.split('-');
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          activeMonthNotifier.value = DateTime(y, m);
        }
      }
    } catch (_) {}
  }

  void setActiveMonth(DateTime dt) async {
    activeMonthNotifier.value = DateTime(dt.year, dt.month);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedCoverMonth, DateFormat('yyyy-MM').format(dt));
    } catch (_) {}
  }

  void resetToCurrentMonth() async {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    activeMonthNotifier.value = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedCoverMonth, DateFormat('yyyy-MM').format(now));
    } catch (_) {}
  }

  void previousMonth() {
    final cur = activeMonth;
    final prev = DateTime(cur.year, cur.month - 1);
    setActiveMonth(prev);
  }

  void nextMonth() {
    final cur = activeMonth;
    final next = DateTime(cur.year, cur.month + 1);
    setActiveMonth(next);
  }

  /// Verifica si el usuario acaba de ingresar a un nuevo mes sin carátula personalizada
  Future<bool> shouldPromptNewMonthCover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVisited = prefs.getString(_keyLastVisitedMonth);
      final currentReal = currentRealMonthYearString;

      // Si ya visitó y reconoció este mes, no volver a interrumpir
      if (lastVisited == currentReal) {
        return false;
      }

      // Consultar si ya diseñó la carátula de este mes en el servidor
      final cover = await ApiService.instance.getMonthlyCover(currentReal);
      if (!cover.isCustom) {
        return true;
      } else {
        // Ya tiene carátula personalizada, marcarlo como visitado
        await prefs.setString(_keyLastVisitedMonth, currentReal);
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// Marca que el mes actual ya fue procesado o que el usuario eligió "Omitir"
  Future<void> markCurrentMonthHandled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastVisitedMonth, currentRealMonthYearString);
    } catch (_) {}
  }
}
