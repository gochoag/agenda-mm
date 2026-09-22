import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sticky_note.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/month_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/user_filter_bar.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<StickyNote> _notes = [];
  bool _isLoading = true;
  int? _filterUserId; // Para el Admin: null = todas, o id específico
  List<User> _usersList = [];

  User? get currentUser => ApiService.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadNotes();
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

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await ApiService.instance.getNotes(userId: _filterUserId);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Error al cargar notas: $e', isError: true);
      }
    }
  }

  void _openNoteEditor({StickyNote? note}) {
    final textController = TextEditingController(text: note?.content ?? '');
    String selectedColorHex = note?.color ?? '#FFF59D';
    String selectedFontFamily = note?.fontFamily ?? 'handwriting';
    bool isPinned = note?.isPinned ?? false;

    const fontOptions = [
      {'id': 'handwriting', 'label': 'Manuscrita'},
      {'id': 'casual', 'label': 'Casual'},
      {'id': 'mono', 'label': 'Cifras'},
      {'id': 'clean', 'label': 'Limpia'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final currentColor = _hexToColor(selectedColorHex);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera del modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note == null ? 'Nueva Nota Adhesiva' : 'Editar Nota',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: isPinned ? Colors.red.shade700 : Colors.black54,
                            ),
                            tooltip: 'Fijar nota',
                            onPressed: () {
                              setModalState(() => isPinned = !isPinned);
                            },
                          ),
                          if (note != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.black54),
                              tooltip: 'Eliminar',
                              onPressed: () async {
                                Navigator.pop(modalCtx);
                                _confirmDelete(note.id);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Área de texto libre con tipografía en vivo
                  Container(
                    constraints: const BoxConstraints(minHeight: 140, maxHeight: 240),
                    child: TextField(
                      controller: textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: StickyNote.getFontTextStyle(
                        selectedFontFamily,
                        fontSize: selectedFontFamily == 'mono' ? 16 : 19,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe lo que quieras (gastos, saldos, cálculos, listas rápidas)...',
                        hintStyle: StickyNote.getFontTextStyle(
                          selectedFontFamily,
                          fontSize: selectedFontFamily == 'mono' ? 15 : 17,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector de Tipografía
                  const Text(
                    'Tipo de letra:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: fontOptions.map((f) {
                        final id = f['id'] as String;
                        final label = f['label'] as String;
                        final isSelected = selectedFontFamily == id;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            selected: isSelected,
                            selectedColor: Colors.black87,
                            backgroundColor: Colors.black.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: isSelected ? Colors.black87 : Colors.black12,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedFontFamily = id;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector de Colores Post-it reales
                  const Text(
                    'Color del papel:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppColors.postItColors.map((colorMap) {
                        final hex = colorMap['hex'] as String;
                        final color = colorMap['color'] as Color;
                        final isSelected = selectedColorHex == hex;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColorHex = hex;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black87 : Colors.black12,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 18, color: Colors.black87)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón Guardar
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final content = textController.text.trim();
                      if (content.isEmpty) return;

                      Navigator.pop(modalCtx);

                      try {
                        if (note == null) {
                          await ApiService.instance.createNote(
                            content: content,
                            color: selectedColorHex,
                            fontFamily: selectedFontFamily,
                            isPinned: isPinned,
                            monthYear: MonthStateService.instance.activeMonthYearString,
                          );
                        } else {
                          await ApiService.instance.updateNote(
                            note.id,
                            content: content,
                            color: selectedColorHex,
                            fontFamily: selectedFontFamily,
                            isPinned: isPinned,
                          );
                        }
                        _loadNotes();
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.show(context, 'Error al guardar: $e', isError: true);
                        }
                      }
                    },
                    child: const Text('Guardar Nota', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _hexToColor(String hexCode) {
    try {
      String hex = hexCode.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFFFFF59D);
    }
  }

  Future<void> _confirmDelete(int noteId) async {
    final ok = await AppDialogs.confirmAction(
      context,
      title: 'Eliminar Nota',
      message: '¿Estás seguro de que deseas eliminar esta nota adhesiva? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (ok) {
      try {
        await ApiService.instance.deleteNote(noteId);
        if (mounted) {
          AppSnackBar.show(context, 'Nota eliminada correctamente', isSuccess: true);
        }
        _loadNotes();
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context, 'Error al eliminar: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Notas Adhesivas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar notas',
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          const MonthSelectorBar(),
          if (currentUser?.isAdmin == true)
            UserFilterBar(
              title: 'Ver notas:',
              users: _usersList,
              currentUserId: currentUser?.id,
              selectedUserId: _filterUserId,
              allLabel: 'Todas',
              myLabel: 'Mis Notas',
              onSelected: (userId) {
                setState(() => _filterUserId = userId);
                _loadNotes();
              },
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay notas adhesivas aún',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toca el botón + para registrar una nota o apunte',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: MasonryGridView.count(
                          padding: const EdgeInsets.all(16),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return _buildPostItCard(note);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFFFFF59D), // Amarillo post-it
        onPressed: () => _openNoteEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Nota'),
      ),
    );
  }

  Widget _buildPostItCard(StickyNote note) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _openNoteEditor(note: note),
        child: Container(
          decoration: BoxDecoration(
            color: note.colorValue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior de la tarjeta (pin y autor si aplica)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentUser?.isAdmin == true && note.username != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.username!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                ],
              ),
              if (currentUser?.isAdmin == true && note.username != null)
                const SizedBox(height: 6),

              // Contenido Libre respetando la tipografía elegida
              Text(
                note.content,
                style: note.getTextStyle(
                  fontSize: note.fontFamily == 'mono' ? 14 : 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
