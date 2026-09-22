import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/month_state_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/user_filter_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<CalendarEvent> _events = [];
  bool _isLoading = true;
  int? _filterUserId;
  List<User> _usersList = [];

  User? get currentUser => ApiService.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    if (currentUser?.isAdmin == true) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.instance.getAdminUsers();
      if (mounted) setState(() => _usersList = users);
    } catch (_) {}
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await ApiService.instance.getCalendarEvents(userId: _filterUserId);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Error al cargar eventos: $e', isError: true);
      }
    }
  }

  void _openEventEditor({CalendarEvent? event}) {
    final detailController = TextEditingController(text: event?.detail ?? '');
    DateTime selectedDate = MonthStateService.instance.isViewingCurrentMonth
        ? DateTime.now()
        : DateTime(MonthStateService.instance.activeMonth.year, MonthStateService.instance.activeMonth.month, 1, 9, 0);
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    bool shouldNotify = true;

    if (event != null && event.eventDate.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(event.eventDate);
        selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
          final formattedTime = selectedTime.format(modalCtx);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event == null ? 'Nuevo Evento / Tarea' : 'Editar Evento',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campo Detalle
                  TextField(
                    controller: detailController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detalle de la actividad',
                      hintText: 'Ej. Entrega de lote 2, Cobro pendiente, etc.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Fecha y Hora
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: modalCtx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(formattedDate),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: modalCtx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(formattedTime),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Switch de Recordatorio Local
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Activar recordatorio push',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Notificará en la fecha y hora seleccionada',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: shouldNotify,
                    onChanged: (val) => setModalState(() => shouldNotify = val),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final detail = detailController.text.trim();
                      if (detail.isEmpty) return;

                      final finalDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      final dateStr = finalDateTime.toIso8601String();

                      Navigator.pop(modalCtx);

                      try {
                        if (event == null) {
                          final newEv = await ApiService.instance.createCalendarEvent(
                            detail: detail,
                            eventDate: dateStr,
                          );
                          if (shouldNotify) {
                            final ok = await NotificationService.instance.scheduleNotification(                              id: newEv.id,
                              title: 'Recordatorio de Agenda',
                              body: detail,
                              scheduledDate: finalDateTime,
                            );
                            if (mounted && ok) {
                              AppSnackBar.show(
                                context,
                                'Recordatorio fijado para ${DateFormat('dd/MM HH:mm').format(finalDateTime)}',
                                isSuccess: true,
                              );
                            }
                          }
                        } else {
                          final updatedEv = await ApiService.instance.updateCalendarEvent(
                            event.id,
                            detail: detail,
                            eventDate: dateStr,
                          );
                          if (shouldNotify) {
                            final ok = await NotificationService.instance.scheduleNotification(
                              id: updatedEv.id,
                              title: 'Recordatorio de Agenda',
                              body: detail,
                              scheduledDate: finalDateTime,
                            );
                            if (mounted && ok) {
                              AppSnackBar.show(
                                context,
                                'Recordatorio actualizado para ${DateFormat('dd/MM HH:mm').format(finalDateTime)}',
                                isSuccess: true,
                              );
                            }
                          }
                        }
                        _loadEvents();
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.show(context, 'Error al guardar: $e', isError: true);
                        }
                      }
                    },
                    child: const Text('Guardar en Calendario', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateEventStatus(CalendarEvent event, String newStatus) async {
    try {
      await ApiService.instance.updateCalendarEvent(event.id, status: newStatus);
      _loadEvents();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _toggleStatus(CalendarEvent event) async {
    final newStatus = event.isCompleted ? 'pendiente' : 'completado';
    await _updateEventStatus(event, newStatus);
  }

  Future<bool> _confirmDeleteEvent(int id) async {
    final ok = await AppDialogs.confirmAction(
      context,
      title: 'Eliminar Evento',
      message: '¿Estás seguro de que deseas eliminar este evento del calendario? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (ok) {
      try {
        await ApiService.instance.deleteCalendarEvent(id);
        await NotificationService.instance.cancelNotification(id);
        if (mounted) {
          AppSnackBar.show(context, 'Evento eliminado correctamente', isSuccess: true);
        }
        _loadEvents();
        return true;
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context, 'Error al eliminar: $e', isError: true);
        }
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pendingEvents = _events.where((e) => !e.isCompleted).toList();
    final completedEvents = _events.where((e) => e.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          const MonthSelectorBar(),
          if (currentUser?.isAdmin == true)
            UserFilterBar(
              users: _usersList,
              currentUserId: currentUser?.id,
              selectedUserId: _filterUserId,
              allLabel: 'Todos',
              myLabel: 'Mis Eventos',
              onSelected: (userId) {
                setState(() => _filterUserId = userId);
                _loadEvents();
              },
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay eventos programados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toca + para agregar un nuevo compromiso o fecha',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (pendingEvents.isNotEmpty) ...[
                              _buildSectionHeader('Pendientes (${pendingEvents.length})', Icons.schedule),
                              ...pendingEvents.map((e) => _buildEventCard(e)),
                              const SizedBox(height: 16),
                            ],
                            if (completedEvents.isNotEmpty) ...[
                              _buildSectionHeader('Completados (${completedEvents.length})', Icons.check_circle_outline),
                              ...completedEvents.map((e) => _buildEventCard(e)),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openEventEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Evento'),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    String formattedDateStr = event.eventDate;
    try {
      final dt = DateTime.parse(event.eventDate);
      formattedDateStr = DateFormat('EEE d MMM yyyy • HH:mm', 'es').format(dt);
    } catch (_) {}

    return RepaintBoundary(
      child: Dismissible(
        key: Key('calendar_event_${event.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await _confirmDeleteEvent(event.id);
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: event.isCompleted ? Colors.green.shade200 : AppColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openEventEditor(event: event),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Contenido y Fecha a la izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.detail,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: event.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              formattedDateStr,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (currentUser?.isAdmin == true && event.username != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.username!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Círculo de estado a la DERECHA
                  IconButton(
                    icon: Icon(
                      event.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: event.isCompleted ? Colors.green.shade600 : AppColors.textSecondary,
                      size: 26,
                    ),
                    tooltip: event.isCompleted ? 'Completado' : 'Pendiente',
                    onPressed: () => _toggleStatus(event),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
