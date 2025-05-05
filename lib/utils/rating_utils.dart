import 'package:flutter/material.dart';

/// Utilidades para manejar las valoraciones de los jugadores
/// y los colores asociados a diferentes estadísticas
class RatingUtils {
  
  /// Obtiene el color correspondiente al promedio de habilidad del jugador
  static Color getAverageColor(double average) {
    if (average >= 90) return Colors.purple;
    if (average >= 80) return Colors.green.shade800;
    if (average >= 70) return Colors.blue.shade800;
    if (average >= 60) return Colors.orange.shade800;
    return Colors.red.shade800;
  }
  
  /// Genera un degradado de color basado en la valoración
  static LinearGradient getRatingGradient(double rating) {
    final baseColor = getAverageColor(rating);
    
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  /// Obtiene el color para el texto según el valor de una estadística
  static Color getStatTextColor(int value) {
    if (value >= 90) return Colors.purple;
    if (value >= 80) return Colors.green.shade700;
    if (value >= 70) return Colors.blue.shade700;
    if (value >= 60) return Colors.orange.shade700;
    if (value >= 50) return Colors.orange.shade900;
    return Colors.red.shade700;
  }
  
  /// Obtiene el color de fondo para la tarjeta del jugador según su posición
  static Color getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'portero':
      case 'pt':
      case 'gk':
        return Colors.grey.shade800;
      case 'defensa':
      case 'df':
      case 'def':
        return Colors.blue.shade800;
      case 'mediocampista':
      case 'mc':
      case 'mid':
        return Colors.green.shade800;
      case 'delantero':
      case 'dl':
      case 'fw':
        return Colors.red.shade800;
      default:
        return Colors.purple.shade800;
    }
  }
  
  /// Obtiene el icono asociado a la posición del jugador
  static IconData getPositionIcon(String position) {
    switch (position.toLowerCase()) {
      case 'portero':
      case 'pt':
      case 'gk':
        return Icons.accessibility_new;
      case 'defensa':
      case 'df':
      case 'def':
        return Icons.shield;
      case 'mediocampista':
      case 'mc':
      case 'mid':
        return Icons.swap_horiz;
      case 'delantero':
      case 'dl':
      case 'fw':
        return Icons.sports_soccer;
      default:
        return Icons.person;
    }
  }
  
  /// Obtiene una forma abreviada de la posición
  static String getShortPosition(String position) {
    switch (position.toLowerCase()) {
      case 'portero':
        return 'PT';
      case 'defensa':
        return 'DF';
      case 'mediocampista':
        return 'MC';
      case 'delantero':
        return 'DL';
      default:
        return position.toUpperCase().substring(0, min(2, position.length));
    }
  }
  
  /// Devuelve min(a, b) dado que Dart no tiene una función min en el ámbito global
  static int min(int a, int b) => a < b ? a : b;
  
  /// Calcula el promedio de las estadísticas de un jugador
  static double calculateAverageRating(Map<String, dynamic> player) {
    if (player.containsKey('tiro') && 
        player.containsKey('regate') && 
        player.containsKey('tecnica') && 
        player.containsKey('defensa') && 
        player.containsKey('velocidad') && 
        player.containsKey('aguante') && 
        player.containsKey('control')) {
      
      final stats = [
        player['tiro'] ?? 0,
        player['regate'] ?? 0,
        player['tecnica'] ?? 0,
        player['defensa'] ?? 0,
        player['velocidad'] ?? 0,
        player['aguante'] ?? 0,
        player['control'] ?? 0,
      ];
      
      return stats.isNotEmpty 
          ? stats.reduce((a, b) => a + b) / stats.length 
          : 0;
    }
    
    return 0;
  }
}
