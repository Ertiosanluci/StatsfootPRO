import 'package:flutter/material.dart';

/// Widget que muestra el encabezado con la información principal de un jugador
class PlayerHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  
  const PlayerHeaderWidget({
    Key? key,
    required this.player,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Foto del jugador con círculo de media superpuesto
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Foto
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: player['foto_perfil'] != null
                  ? NetworkImage(player['foto_perfil'])
                  : null,
              child: player['foto_perfil'] == null
                  ? const Icon(Icons.person, color: Colors.white, size: 60)
                  : null,
            ),

            // Círculo de media
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMediaColor(player['media'] ?? 0),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${player['media'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Nombre del jugador
        Text(
          player['nombre'] ?? 'Sin nombre',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Posición y calificación
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(player['posicion']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getPositionColor(player['posicion']).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                player['posicion'] ?? 'Jugador',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Estrellas de calificación
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  "${player['calificacion'] ?? 0}",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  /// Devuelve un color basado en la posición del jugador
  Color _getPositionColor(String? position) {
    switch (position) {
      case 'Delantero': return Colors.red.shade400;
      case 'Mediocampista': return Colors.green.shade400;
      case 'Defensa': return Colors.blue.shade400;
      case 'Portero': return Colors.orange.shade400;
      default: return Colors.purple.shade400;
    }
  }
  
  /// Devuelve un color basado en la media del jugador
  Color _getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade500;
    if (media >= 75) return Colors.lightGreen.shade500;
    if (media >= 65) return Colors.amber.shade500;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }
}
