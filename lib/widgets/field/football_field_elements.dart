import 'package:flutter/material.dart';
import '../painters/glass_painter.dart';

/// Widget que renderiza los elementos de un campo de fútbol
/// como líneas, círculos, áreas de penalti, etc.
class FootballFieldElements extends StatelessWidget {
  final double width;
  final double height;
  final bool isTeamA;
  
  const FootballFieldElements({
    Key? key,
    required this.width,
    required this.height,
    required this.isTeamA,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Línea central
        Positioned(
          top: height / 2 - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        
        // Círculo central
        Positioned(
          top: height / 2 - width * 0.1,
          left: width / 2 - width * 0.1,
          child: Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
          ),
        ),
        
        // Punto central
        Positioned(
          top: height / 2 - 4,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti superior
        Positioned(
          top: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería superior
        Positioned(
          top: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti superior
        Positioned(
          top: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti inferior
        Positioned(
          bottom: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti inferior
        Positioned(
          bottom: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Portería superior
        Positioned(
          top: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        
        // Portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        
        // Añadir reflejo/brillo para dar efecto profesional
        Positioned.fill(
          child: CustomPaint(
            painter: GlassPainter(),
          ),
        ),
      ],
    );
  }
}
