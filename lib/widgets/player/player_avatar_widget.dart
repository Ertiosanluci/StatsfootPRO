import 'package:flutter/material.dart';
import '../painters/avatar_glow_painter.dart';

/// Widget que muestra el avatar de un jugador con su foto de perfil o iniciales,
/// efectos de brillo y un indicador de su valoración media.
class PlayerAvatarWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isTeamA;
  final double posX;
  final double posY;
  final bool isMVP;
  final bool isFinished;
  
  const PlayerAvatarWidget({
    Key? key,
    required this.player,
    required this.isTeamA,
    required this.posX,
    required this.posY,
    required this.isMVP,
    required this.isFinished,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Calcular promedio de habilidades si están disponibles
    double average = 0;
    if (player.containsKey('tiro') && 
        player.containsKey('regate') && 
        player.containsKey('tecnica') && 
        player.containsKey('defensa') && 
        player.containsKey('velocidad') && 
        player.containsKey('aguante') && 
        player.containsKey('control')) {
      
      final List<num> stats = [
        player['tiro'] ?? 0,
        player['regate'] ?? 0,
        player['tecnica'] ?? 0,
        player['defensa'] ?? 0,
        player['velocidad'] ?? 0,
        player['aguante'] ?? 0,
        player['control'] ?? 0,
      ];
      
      average = stats.isNotEmpty 
          ? stats.reduce((a, b) => a + b) / stats.length 
          : 0;
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Fondo con efecto de brillo
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isTeamA 
                  ? [Colors.blue.shade600, Colors.blue.shade900] 
                  : [Colors.red.shade600, Colors.red.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: (isMVP && isFinished) ? Colors.amber : Colors.white,
              width: (isMVP && isFinished) ? 3 : 2,
            ),
            boxShadow: [
              if (isMVP && isFinished)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              BoxShadow(
                color: (isTeamA ? Colors.blue : Colors.red).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: player['foto_perfil'] != null
                ? ClipOval(
                    child: Image.network(
                      player['foto_perfil'],
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          player['nombre'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    player['nombre'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        // Efecto de brillo
        Positioned.fill(
          child: ClipOval(
            child: CustomPaint(
              painter: AvatarGlowPainter(),
            ),
          ),
        ),
        
        // Mostrar puntuación del jugador (si está disponible)
        if (average > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getAverageColor(average).withOpacity(0.8),
                    _getAverageColor(average),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  average.round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Devuelve un color basado en la puntuación media del jugador
  Color _getAverageColor(double average) {
    if (average >= 85) return Colors.green.shade700;
    if (average >= 70) return Colors.lime.shade700;
    if (average >= 60) return Colors.amber.shade700;
    if (average >= 40) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
