import 'package:flutter/material.dart';

/// Widget que muestra la tarjeta de un jugador en la lista de jugadores
class PlayerCardWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final Function() onTap;
  final Function() onLongPress;
  
  const PlayerCardWidget({
    Key? key,
    required this.player,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determinar colores según posición
    final Color positionColor = _getPositionColor(player['posicion']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: positionColor.withOpacity(0.1),
          highlightColor: positionColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Media del jugador
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getMediaColor(player['media'] ?? 0),
                        _getMediaColor(player['media'] ?? 0).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getMediaColor(player['media'] ?? 0).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${player['media'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Foto y nombre
                Expanded(
                  child: Row(
                    children: [
                      // Foto de perfil
                      Hero(
                        tag: 'player_${player['id']}',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: positionColor.withOpacity(0.3), width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: player['foto_perfil'] != null
                                ? Image.network(
                              player['foto_perfil'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.white70, size: 30),
                            )
                                : const Icon(Icons.person, color: Colors.white70, size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Nombre y posición
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player['nombre'] ?? 'Sin nombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: positionColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: positionColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getShortPosition(player['posicion'] ?? ''),
                                style: TextStyle(
                                  color: positionColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón de opciones
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: onLongPress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Obtiene el color asociado a la posición del jugador
  Color _getPositionColor(String? position) {
    switch (position) {
      case 'Delantero': 
        return Colors.red.shade400;
      case 'Mediocampista': 
        return Colors.green.shade400;
      case 'Defensa': 
        return Colors.blue.shade400;
      case 'Portero': 
        return Colors.orange.shade400;
      default: 
        return Colors.grey;
    }
  }
  
  /// Obtiene el color asociado a la media del jugador
  Color _getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade500;
    if (media >= 75) return Colors.lightGreen.shade500;
    if (media >= 65) return Colors.amber.shade500;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }
  
  /// Devuelve la abreviatura de la posición
  String _getShortPosition(String position) {
    switch (position) {
      case 'Delantero': return 'DEL';
      case 'Mediocampista': return 'MED';
      case 'Defensa': return 'DEF';
      case 'Portero': return 'POR';
      default: return position;
    }
  }
}
