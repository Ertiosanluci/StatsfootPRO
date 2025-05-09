import 'package:flutter/material.dart';
import 'painters.dart';
import 'position_utils.dart';

/// Widget para mostrar el avatar del jugador con sus estadísticas
class PlayerAvatar extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isTeamClaro;
  final String? mvpId;
  final bool isFinished;
  
  const PlayerAvatar({
    Key? key, 
    required this.player, 
    required this.isTeamClaro,
    this.mvpId,
    this.isFinished = false,
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
      
      final stats = [
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
    
    // Verificar si el jugador es MVP
    final String playerId = player['id'].toString();
    final bool isMVP = mvpId == playerId;
    
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
              colors: isTeamClaro 
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
                  offset: Offset(0, 0),
                ),
              BoxShadow(
                color: (isTeamClaro ? Colors.blue : Colors.red).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
              BoxShadow(
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
                          player['nombre'].isNotEmpty 
                              ? player['nombre'][0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    player['nombre'].isNotEmpty 
                        ? player['nombre'][0].toUpperCase()
                        : '?',
                    style: TextStyle(
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
                    PositionUtils.getAverageColor(average).withOpacity(0.8),
                    PositionUtils.getAverageColor(average),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  average.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
        // Estrella MVP (ahora en la parte inferior derecha y evitando solapamiento)
        if (isMVP && isFinished)
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}