import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Painter para el efecto de reflejo del campo
class GlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height / 3),
        [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.01),
        ],
      );
    
    // Crear un suave reflejo en la parte superior
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter para el efecto de brillo en avatar
class AvatarGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width / 2, size.height / 2),
        [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
        ],
      );
    
    canvas.drawCircle(
      Offset(size.width / 4, size.height / 4),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}