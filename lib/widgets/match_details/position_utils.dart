import 'package:flutter/material.dart';

/// Utilidades para manejar las posiciones de los jugadores en el campo
class PositionUtils {
  /// Método para obtener posiciones predeterminadas según la formación
  static List<Offset> getDefaultPositions(int totalPlayers, bool isTeamA) {
    List<List<double>> positions;
    
    // Posiciones relativas (x, y) donde x e y están entre 0 y 1
    switch (totalPlayers) {
      case 5:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.4],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.5, 0.7],    // Defensa / Portero
        ];
        break;
      case 6:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.3, 0.6],    // Defensa izquierdo
          [0.7, 0.6],    // Defensa derecho
        ];
        break;
      case 7:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.25],   // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.25],   // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo izquierdo
          [0.7, 0.5],    // Mediocampista defensivo derecho
          [0.5, 0.7],    // Defensa central / Portero
        ];
        break;
      case 8:
        positions = [
          [0.3, 0.15],   // Delantero izquierdo
          [0.7, 0.15],   // Delantero derecho
          [0.2, 0.3],    // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo
          [0.7, 0.5],    // Defensa central
          [0.5, 0.7],    // Portero
        ];
        break;
      default:
        // Para otros formatos que no estén definidos, distribuir uniformemente
        positions = List.generate(totalPlayers, (index) {
          double y = 0.15 + (0.6 * index / (totalPlayers - 1 > 0 ? totalPlayers - 1 : 1));
          double x = 0.5;
          if (index % 2 == 1) {
            x = 0.3 + (0.4 * (index / totalPlayers));
          } else if (index % 2 == 0 && index > 0) {
            x = 0.7 - (0.4 * (index / totalPlayers));
          }
          return [x, y];
        });
    }
    
    // Convertir a lista de Offset
    List<Offset> offsets = positions.map((pos) {
      // Si es el equipo oscuro, invertir la posición vertical
      double dy = isTeamA ? pos[1] : 1.0 - pos[1];
      return Offset(pos[0], dy);
    }).toList();
    
    return offsets;
  }
  
  /// Devuelve un color basado en el promedio de habilidad del jugador
  static Color getAverageColor(double average) {
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }
}