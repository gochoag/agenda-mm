import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpiralDoodlePainter extends CustomPainter {
  final Color color;

  SpiralDoodlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, 3.2 * (size.width / 48.0))
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    // Dibujar espiral artesanal hecha a mano (como en la foto de la libreta)
    const turns = 2.4;
    const points = 60;
    final maxRadius = math.min(size.width, size.height) * 0.44;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final angle = t * turns * 2 * math.pi;
      final radius = t * maxRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpiralDoodlePainter oldDelegate) => oldDelegate.color != color;
}

class SparkleDoodlePainter extends CustomPainter {
  final Color color;

  SparkleDoodlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width / 2;
    final h = size.height / 2;

    // Dibujar destello / estrella de 4 puntas estilo bullet journal
    final path = Path();
    path.moveTo(center.dx, center.dy - h);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + w, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + h);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - w, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - h);
    path.close();

    canvas.drawPath(path, paint);

    // Destello menor en diagonal opcional
    final miniPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - w * 0.35, center.dy - h * 0.35),
      Offset(center.dx + w * 0.35, center.dy + h * 0.35),
      miniPaint,
    );
    canvas.drawLine(
      Offset(center.dx + w * 0.35, center.dy - h * 0.35),
      Offset(center.dx - w * 0.35, center.dy + h * 0.35),
      miniPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SparkleDoodlePainter oldDelegate) => oldDelegate.color != color;
}
