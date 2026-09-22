import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monthly_cover.dart';
import 'doodle_painter.dart';
import 'notebook_paper_painter.dart';

class CoverCardView extends StatelessWidget {
  static const double baseDesignWidth = 360.0;

  final MonthlyCover cover;
  final bool showSpiral;
  final String? selectedElementId;
  final void Function(CoverElement element)? onElementTap;
  final void Function(CoverElement element)? onElementDoubleTap;
  final void Function(CoverElement element, ScaleStartDetails details)? onElementScaleStart;
  final void Function(CoverElement element, ScaleUpdateDetails details, double canvasWidth, double canvasHeight)? onElementScaleUpdate;

  const CoverCardView({
    super.key,
    required this.cover,
    this.showSpiral = true,
    this.selectedElementId,
    this.onElementTap,
    this.onElementDoubleTap,
    this.onElementScaleStart,
    this.onElementScaleUpdate,
  });

  TextStyle _getStyle(String fontFamily, double fontSize, Color color) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );
    } catch (_) {
      return GoogleFonts.caveat(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final double scaleFactor = width / baseDesignWidth;

          return CustomPaint(
            size: Size(width, height),
            painter: NotebookPaperPainter(
              backgroundType: cover.backgroundType,
              paperColor: cover.backgroundColor,
              showSpiral: showSpiral,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: cover.elements.map((el) {
                final isSelected = selectedElementId == el.id;
                final posX = el.x * width;
                final posY = el.y * height;

                Widget content;
                if (el.type == 'text') {
                  content = Text(
                    el.text,
                    textAlign: TextAlign.center,
                    style: _getStyle(el.fontFamily, el.fontSize * el.scale * scaleFactor, el.color),
                  );
                } else if (el.type == 'doodle_spiral') {
                  final s = 48.0 * el.scale * scaleFactor;
                  content = CustomPaint(
                    size: Size(s, s),
                    painter: SpiralDoodlePainter(color: el.color),
                  );
                } else if (el.type == 'doodle_sparkle') {
                  final s = 42.0 * el.scale * scaleFactor;
                  content = CustomPaint(
                    size: Size(s, s),
                    painter: SparkleDoodlePainter(color: el.color),
                  );
                } else if (el.type == 'sticker') {
                  content = Text(
                    el.extra.isNotEmpty ? el.extra : '✨',
                    style: TextStyle(fontSize: 34.0 * el.scale * scaleFactor),
                  );
                } else {
                  content = const SizedBox.shrink();
                }

                return Positioned(
                  left: posX,
                  top: posY,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Transform.rotate(
                      angle: el.rotation,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onElementTap?.call(el),
                        onDoubleTap: onElementDoubleTap != null ? () => onElementDoubleTap!(el) : null,
                        onScaleStart: onElementScaleStart != null ? (details) => onElementScaleStart!(el, details) : null,
                        onScaleUpdate: onElementScaleUpdate != null ? (details) => onElementScaleUpdate!(el, details, width, height) : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: isSelected
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.blueAccent.withValues(alpha: 0.12),
                                )
                              : null,
                          child: content,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
