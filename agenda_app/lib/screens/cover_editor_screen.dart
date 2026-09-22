import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monthly_cover.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/cover_card_view.dart';

class CoverEditorScreen extends StatefulWidget {
  final String monthYear;
  final MonthlyCover? initialCover;

  const CoverEditorScreen({
    super.key,
    required this.monthYear,
    this.initialCover,
  });

  @override
  State<CoverEditorScreen> createState() => _CoverEditorScreenState();
}

class _CoverEditorScreenState extends State<CoverEditorScreen> with SingleTickerProviderStateMixin {
  late MonthlyCover _cover;
  bool _isLoading = false;
  bool _isSaving = false;
  CoverElement? _selectedElement;
  late TabController _tabController;

  // Paleta de marcadores inspirada en la libreta artesanal
  final List<Map<String, dynamic>> _markerColors = [
    {'name': 'Rosa Marcador', 'color': const Color(0xFFE11D48)},
    {'name': 'Morado Espiral', 'color': const Color(0xFF9333EA)},
    {'name': 'Amarillo Abundancia', 'color': const Color(0xFFEAB308)},
    {'name': 'Naranja Cálido', 'color': const Color(0xFFEA580C)},
    {'name': 'Verde Menta', 'color': const Color(0xFF059669)},
    {'name': 'Azul Celeste', 'color': const Color(0xFF0284C7)},
    {'name': 'Negro Tinta', 'color': const Color(0xFF0F172A)},
    {'name': 'Dorado Suave', 'color': const Color(0xFFD97706)},
  ];

  final List<String> _calligraphyFonts = [
    'Caveat',
    'Dancing Script',
    'Pacifico',
    'Kalam',
    'Sacramento',
    'Marck Script',
  ];

  // Base para manipulación con gestos táctiles
  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;

  final Map<String, List<String>> _stickerCategories = {
    '🌸 Flores & Naturaleza': [
      '🌸', '🌺', '🌻', '🌷', '🌼', '🌹', '🌿', '🍀', '🍂', '🍄', '🌵', '🌴', '🌱', '🪴', '🍁'
    ],
    '💖 Amor & Caritas': [
      '💖', '💕', '💗', '💓', '✨', '🥰', '😊', '🥹', '😻', '💌', '💋', '🎀', '🧸', '🤍', '💫'
    ],
    '☕ Libreta & Café': [
      '☕', '📖', '📝', '✏️', '📅', '🎨', '🎧', '🕯️', '🥐', '🍓', '🧋', '🧁', '🍩', '🍫', '🍰'
    ],
    '⭐ Astrología & Cielo': [
      '⭐', '🌟', '🌙', '☀️', '☁️', '🌈', '⚡', '❄️', '🫧', '🦋', '🐝', '🪐', '🔮', '🕊️'
    ],
    '🎉 Metas & Celebración': [
      '🎯', '🏆', '🎖️', '🥂', '🎂', '🎈', '🎁', '🚀', '💡', '📌', '🏷️', '🔑', '🍀', '🪄'
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialCover != null) {
      _cover = widget.initialCover!;
      if (_cover.elements.isNotEmpty) {
        _selectedElement = _cover.elements.first;
      }
    } else {
      _loadCover();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCover() async {
    setState(() => _isLoading = true);
    try {
      final cover = await ApiService.instance.getMonthlyCover(widget.monthYear);
      if (mounted) {
        setState(() {
          if (!cover.exists) {
            _cover = MonthlyCover.empty(widget.monthYear);
          } else {
            _cover = cover;
          }
          _isLoading = false;
          if (_cover.elements.isNotEmpty) {
            _selectedElement = _cover.elements.first;
          } else {
            _selectedElement = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Error al cargar carátula: $e', isError: true);
      }
    }
  }

  Future<void> _saveCover() async {
    setState(() => _isSaving = true);
    try {
      _cover.isCustom = true;
      final saved = await ApiService.instance.saveMonthlyCover(_cover);
      if (mounted) {
        setState(() {
          _cover = saved;
          _isSaving = false;
        });
        AppSnackBar.show(context, '¡Carátula guardada con éxito! ✨');
        Navigator.pop(context, _cover);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(context, 'Error al guardar carátula: $e', isError: true);
      }
    }
  }

  void _addNewText() {
    final newEl = CoverElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'text',
      text: 'Nueva Frase',
      x: 0.5,
      y: 0.5,
      fontSize: 28.0,
      fontFamily: 'Caveat',
      color: const Color(0xFFE11D48),
    );
    setState(() {
      _cover.elements.add(newEl);
      _selectedElement = newEl;
      _tabController.animateTo(1); // Cambiar a pestaña texto
    });
  }

  void _addSticker(String emoji) {
    final newEl = CoverElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'sticker',
      x: 0.5,
      y: 0.5,
      scale: 1.0,
      extra: emoji,
      color: Colors.black,
    );
    setState(() {
      _cover.elements.add(newEl);
      _selectedElement = newEl;
    });
  }

  void _openKeyboardEmojiDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.keyboard_alt_outlined, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text('Desde el teclado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abre tu teclado virtual para elegir cualquier emoji, sticker o símbolo:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: 'Ej: 🦄 🌟 🧸 ✨',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                _addSticker(val);
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _handleElementScaleStart(CoverElement el, ScaleStartDetails details) {
    _gestureBaseScale = el.scale;
    _gestureBaseRotation = el.rotation;
    if (_selectedElement?.id != el.id) {
      setState(() {
        _selectedElement = el;
        if (el.type == 'text') {
          _tabController.animateTo(1);
        } else {
          _tabController.animateTo(2); // Pestaña Emojis
        }
      });
    }
  }

  void _handleElementScaleUpdate(CoverElement el, ScaleUpdateDetails details, double canvasWidth, double canvasHeight) {
    setState(() {
      // 1. Desplazamiento
      el.x = (el.x + details.focalPointDelta.dx / canvasWidth).clamp(0.06, 0.94);
      el.y = (el.y + details.focalPointDelta.dy / canvasHeight).clamp(0.06, 0.94);

      // 2. Escala con pellizco (2 dedos)
      if (details.pointerCount > 1 || details.scale != 1.0) {
        el.scale = (_gestureBaseScale * details.scale).clamp(0.35, 3.5);
      }

      // 3. Rotación (2 dedos)
      if (details.pointerCount > 1 || details.rotation != 0.0) {
        el.rotation = _gestureBaseRotation + details.rotation;
      }
    });
  }

  void _deleteSelectedElement() {
    if (_selectedElement == null) return;
    setState(() {
      _cover.elements.removeWhere((e) => e.id == _selectedElement!.id);
      _selectedElement = _cover.elements.isNotEmpty ? _cover.elements.last : null;
    });
  }

  void _editSelectedText({CoverElement? elementToEdit}) {
    final target = elementToEdit ?? _selectedElement;
    if (target == null || target.type != 'text') return;
    _selectedElement = target;
    final controller = TextEditingController(text: target.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Editar Frase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe aquí tu frase o título...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() => target.text = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Canva • ${_cover.title}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Vista Previa',
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () => _showPreviewDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCover,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ÁREA DEL LIENZO (CANVAS DE LA LIBRETA)
          // 1. ÁREA DEL LIENZO (CANVAS DE LA LIBRETA - VERTICAL)
          Expanded(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: AspectRatio(
                  aspectRatio: 0.65, // Proporción vertical de libreta artesanal
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CoverCardView(
                      cover: _cover,
                      showSpiral: true,
                      selectedElementId: _selectedElement?.id,
                      onElementTap: (el) {
                        setState(() {
                          _selectedElement = el;
                          if (el.type == 'text') {
                            _tabController.animateTo(1);
                          } else {
                            _tabController.animateTo(2); // Emojis
                          }
                        });
                      },
                      onElementDoubleTap: (el) {
                        if (el.type == 'text') {
                          _editSelectedText(elementToEdit: el);
                        }
                      },
                      onElementScaleStart: _handleElementScaleStart,
                      onElementScaleUpdate: _handleElementScaleUpdate,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. PANEL DE HERRAMIENTAS INFERIOR
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accent,
                    isScrollable: false,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_rounded, size: 20), text: 'Fondo'),
                      Tab(icon: Icon(Icons.title_rounded, size: 20), text: 'Texto'),
                      Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 20), text: 'Emojis'),
                      Tab(icon: Icon(Icons.tune_rounded, size: 20), text: 'Ajustes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBackgroundTab(),
                        _buildTextTab(),
                        _buildEmojisTab(),
                        _buildElementAdjustTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pestaña 1: Fondos de papel
  Widget _buildBackgroundTab() {
    final backgrounds = [
      {'type': 'grid', 'label': 'Cuadriculado', 'icon': Icons.grid_4x4_rounded},
      {'type': 'dots', 'label': 'Punteado', 'icon': Icons.grain_rounded},
      {'type': 'ruled', 'label': 'Rayado', 'icon': Icons.format_align_left_rounded},
      {'type': 'clean', 'label': 'Liso Pastel', 'icon': Icons.crop_portrait_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'Tipo de Papel de Libreta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: backgrounds.map((bg) {
            final isSelected = _cover.backgroundType == bg['type'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() => _cover.backgroundType = bg['type'] as String);
                  },
                  child: Column(
                    children: [
                      Icon(bg['icon'] as IconData,
                          size: 22, color: isSelected ? AppColors.accent : AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(
                        bg['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.accent : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tono de Papel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _paperColorDot(const Color(0xFFFFFDF7), 'Marfil'),
            _paperColorDot(const Color(0xFFFFFFFF), 'Blanco'),
            _paperColorDot(const Color(0xFFFFF1F2), 'Rosa Suave'),
            _paperColorDot(const Color(0xFFFEF9C3), 'Amarillo Pastel'),
            _paperColorDot(const Color(0xFFE0F2FE), 'Azul Hielo'),
          ],
        ),
      ],
    );
  }

  Widget _paperColorDot(Color color, String label) {
    final isSelected = _cover.backgroundColor == color;
    return GestureDetector(
      onTap: () => setState(() => _cover.backgroundColor = color),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.black26,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Pestaña 2: Edición de texto y caligrafía
  Widget _buildTextTab() {
    final isTextSelected = _selectedElement?.type == 'text';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _addNewText,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar Frase o Título'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        if (isTextSelected) ...[
          const SizedBox(height: 12),
          const Text('Tipografía (Lettering Caligráfico)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _calligraphyFonts.map((font) {
                final isSelected = _selectedElement!.fontFamily == font;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      font,
                      style: GoogleFonts.getFont(font, fontSize: 16),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedElement!.fontFamily = font);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Color de Marcador', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildColorPickerRow(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Doble toque en el texto para editarlo. Usa 2 dedos para girar o agrandar.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Toca un texto en la libreta para editar su fuente y color.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  // Pestaña 3: Emojis y stickers
  Widget _buildEmojisTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Botón para abrir el teclado virtual nativo
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9333EA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
          onPressed: _openKeyboardEmojiDialog,
          icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
          label: const Text(
            'Agregar sticker o emoji del teclado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        ..._stickerCategories.entries.map((cat) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat.key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: cat.value.map((emoji) {
                  return InkWell(
                    onTap: () => _addSticker(emoji),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          );
        }),
      ],
    );
  }

  // Pestaña 4: Ajustes de posición, escala y rotación
  Widget _buildElementAdjustTab() {
    if (_selectedElement == null) {
      return const Center(
        child: Text(
          'Selecciona un elemento en la libreta para ajustar tamaño y rotación.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final el = _selectedElement!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Elemento: ${el.type == 'text' ? el.text : el.type}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelectedElement,
              tooltip: 'Eliminar',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Tamaño / Escala: ${(el.scale * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
        Slider(
          value: el.scale,
          min: 0.5,
          max: 2.2,
          onChanged: (val) => setState(() => el.scale = val),
        ),
        Text('Rotación: ${(el.rotation * 180 / 3.1416).toInt()}°', style: const TextStyle(fontSize: 12)),
        Slider(
          value: el.rotation,
          min: -0.6,
          max: 0.6,
          onChanged: (val) => setState(() => el.rotation = val),
        ),
        if (el.type != 'sticker') ...[
          const Text('Color del Elemento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildColorPickerRow(),
        ],
      ],
    );
  }

  Widget _buildColorPickerRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _markerColors.map((item) {
          final c = item['color'] as Color;
          final isSelected = _selectedElement?.color == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                if (_selectedElement != null) {
                  setState(() => _selectedElement!.color = c);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.white,
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 0.7,
          child: CoverCardView(cover: _cover, showSpiral: true),
        ),
      ),
    );
  }
}
