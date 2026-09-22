import 'package:flutter/material.dart';

class NotebookPaperPainter extends CustomPainter {
  final String backgroundType; // 'grid', 'dots', 'ruled', 'clean'
  final Color paperColor;
  final bool showSpiral;

  NotebookPaperPainter({
    required this.backgroundType,
    this.paperColor = const Color(0xFFFFFDF7),
    this.showSpiral = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo de papel
    final bgPaint = Paint()..color = paperColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final leftMargin = showSpiral ? 36.0 : 16.0;

    // 2. Patrón según tipo de fondo
    if (backgroundType == 'grid') {
      _drawGrid(canvas, size, leftMargin);
    } else if (backgroundType == 'dots') {
      _drawDots(canvas, size, leftMargin);
    } else if (backgroundType == 'ruled') {
      _drawRuled(canvas, size, leftMargin);
    }

    // 3. Margen izquierdo vertical tipo libreta (línea roja suave como en la foto)
    if (backgroundType != 'clean') {
      final marginPaint = Paint()
        ..color = const Color(0xFFFDA4AF).withValues(alpha: 0.6) // Rosa suave de cuaderno
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(leftMargin + 10, 0),
        Offset(leftMargin + 10, size.height),
        marginPaint,
      );
    }

    // 4. Espirales o anillas de libreta en el lateral izquierdo (como en la foto de la chica)
    if (showSpiral) {
      _drawSpirals(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double startX) {
    const spacing = 18.0;
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.45) // Cuadrícula gris/azulada suave
      ..strokeWidth = 0.8;

    // Líneas verticales
    for (double x = startX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawDots(Canvas canvas, Size size, double startX) {
    const spacing = 22.0;
    final dotPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (double x = startX; x < size.width; x += spacing) {
      for (double y = 16.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawRuled(Canvas canvas, Size size, double startX) {
    const spacing = 26.0;
    final linePaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.5) // Azul suave de líneas
      ..strokeWidth = 0.9;

    for (double y = spacing * 1.5; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawSpirals(Canvas canvas, Size size) {
    const ringSpacing = 34.0;
    final holePaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final ringHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = 28.0; y < size.height - 20; y += ringSpacing) {
      // Perforación circular
      canvas.drawCircle(Offset(14, y), 5.5, holePaint);

      // Anilla metálica de espiral
      final path = Path();
      path.moveTo(2, y - 4);
      path.quadraticBezierTo(20, y - 8, 20, y);
      path.quadraticBezierTo(20, y + 8, 2, y + 4);

      canvas.drawPath(path, ringPaint);
      canvas.drawPath(path, ringHighlight);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookPaperPainter oldDelegate) {
    return oldDelegate.backgroundType != backgroundType ||
        oldDelegate.paperColor != paperColor ||
        oldDelegate.showSpiral != showSpiral;
  }
}
