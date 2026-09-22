import 'package:flutter/material.dart';
import '../models/monthly_cover.dart';
import '../services/api_service.dart';
import '../services/month_state_service.dart';
import '../theme/app_theme.dart';
import '../screens/cover_editor_screen.dart';

class MonthSelectorBar extends StatelessWidget {
  final VoidCallback? onMonthChanged;

  const MonthSelectorBar({super.key, this.onMonthChanged});

  static const List<String> _spanishMonths = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  void _openCoverEditor(BuildContext context, String monthYear) async {
    MonthlyCover? cover;
    try {
      cover = await ApiService.instance.getMonthlyCover(monthYear);
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoverEditorScreen(
          monthYear: monthYear,
          initialCover: cover,
        ),
      ),
    ).then((_) => onMonthChanged?.call());
  }

  void _openMonthPicker(BuildContext context) {
    int selectedYear = MonthStateService.instance.activeMonth.year;
    int selectedMonth = MonthStateService.instance.activeMonth.month;

    final currentYear = DateTime.now().year;
    final List<int> availableYears = [
      currentYear - 2,
      currentYear - 1,
      currentYear,
      currentYear + 1,
      currentYear + 2,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final activeMonthStr = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
            final activeMonthName = '${_spanishMonths[selectedMonth - 1]} $selectedYear';

            return SafeArea(
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.72,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cabecera: Título a la izquierda y Filtro de Año a la derecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Carátulas por Mes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // Filtro de Año
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedYear,
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                              onChanged: (newY) {
                                if (newY != null) {
                                  setModalState(() {
                                    selectedYear = newY;
                                  });
                                }
                              },
                              items: availableYears.map((y) {
                                return DropdownMenuItem<int>(
                                  value: y,
                                  child: Text('Año $y'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Botón de Carátula abajo del filtro de año
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF59D), // Amarillo suave post-it
                          foregroundColor: const Color(0xFF854D0E),
                          elevation: 1,
                          side: const BorderSide(color: Color(0xFFFACC15), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          MonthStateService.instance.setActiveMonth(DateTime(selectedYear, selectedMonth));
                          Navigator.pop(ctx);
                          _openCoverEditor(context, activeMonthStr);
                        },
                        icon: const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFF854D0E)),
                        label: Text(
                          'Editar Carátula de $activeMonthName',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Toca un mes para fijar su carátula de inicio:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Lista de los 12 meses del año seleccionado
                    Expanded(
                      child: ListView.builder(
                        itemCount: 12,
                        itemBuilder: (ctx, idx) {
                          final mNum = idx + 1;
                          final mName = _spanishMonths[idx];
                          final isSelected = selectedMonth == mNum &&
                              selectedYear == MonthStateService.instance.activeMonth.year;
                          final now = DateTime.now();
                          final isCurrentReal = now.month == mNum && now.year == selectedYear;

                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: isSelected ? AppColors.accent.withValues(alpha: 0.08) : null,
                            leading: Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            ),
                            title: Text(
                              '$mName $selectedYear',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isCurrentReal
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Mes actual',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              setModalState(() {
                                selectedMonth = mNum;
                              });
                              MonthStateService.instance.setActiveMonth(DateTime(selectedYear, mNum));
                              onMonthChanged?.call();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: MonthStateService.instance.activeMonthNotifier,
      builder: (context, activeDt, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openMonthPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 19,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Carátula: ${MonthStateService.instance.formattedActiveMonthName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
