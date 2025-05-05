import 'package:flutter/material.dart';

/// Clase de utilidades para jugadores
class PlayerUtils {
  
  /// Devuelve un color basado en la posición del jugador
  static Color getPositionColor(String? position) {
    switch (position) {
      case 'Delantero': return Colors.red.shade400;
      case 'Mediocampista': return Colors.green.shade400;
      case 'Defensa': return Colors.blue.shade400;
      case 'Portero': return Colors.orange.shade400;
      default: return Colors.purple.shade400;
    }
  }

  /// Devuelve un icono basado en la posición del jugador
  static IconData getPositionIcon(String? position) {
    switch (position) {
      case 'Delantero': return Icons.sports_soccer;
      case 'Mediocampista': return Icons.sports_handball;
      case 'Defensa': return Icons.shield;
      case 'Portero': return Icons.pan_tool;
      default: return Icons.sports;
    }
  }

  /// Devuelve un color basado en la media del jugador
  static Color getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade500;
    if (media >= 75) return Colors.lightGreen.shade500;
    if (media >= 65) return Colors.amber.shade500;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }

  /// Devuelve un color basado en el valor de una estadística
  static Color getStatColor(int value) {
    if (value >= 85) return Colors.green.shade500;
    if (value >= 70) return Colors.lightGreen.shade500;
    if (value >= 55) return Colors.amber.shade500;
    if (value >= 40) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  /// Devuelve un color basado en la calificación del jugador
  static Color getRatingColor(int rating) {
    if (rating >= 8) return Colors.green.shade400;
    if (rating >= 5) return Colors.amber.shade400;
    if (rating >= 3) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  /// Devuelve la abreviatura de la posición
  static String getShortPosition(String position) {
    switch (position) {
      case 'Delantero': return 'DEL';
      case 'Mediocampista': return 'MED';
      case 'Defensa': return 'DEF';
      case 'Portero': return 'POR';
      default: return position;
    }
  }

  /// Devuelve la abreviatura del nombre de la estadística
  static String getShortStatName(String statName) {
    switch (statName) {
      case 'Tiro': return 'TIRO';
      case 'Regate': return 'REG';
      case 'Técnica': return 'TEC';
      case 'Defensa': return 'DEF';
      case 'Velocidad': return 'VEL';
      case 'Aguante': return 'AGU';
      case 'Control': return 'CTL';
      default: return statName;
    }
  }
}
