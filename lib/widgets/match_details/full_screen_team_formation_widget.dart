import 'package:flutter/material.dart';
import '../painters/avatar_glow_painter.dart';

/// Widget que muestra la formación de un equipo en la cancha en pantalla completa
class FullScreenTeamFormationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, Offset> positions;
  final bool isTeamClaro;
  final String? mvpTeamClaro;
  final String? mvpTeamOscuro;
  final bool isPartidoFinalizado;
  final Function(Map<String, dynamic>, bool) onPlayerTap;
  
  const FullScreenTeamFormationWidget({
    Key? key,
    required this.players,
    required this.positions,
    required this.isTeamClaro,
    this.mvpTeamClaro,
    this.mvpTeamOscuro,
    required this.isPartidoFinalizado,
    required this.onPlayerTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final Color teamColor = isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        // Usar toda la pantalla para el campo
        double fieldWidth = maxWidth;
        double fieldHeight = maxHeight;
        
        return SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Campo de fútbol que ocupa toda la pantalla
              Container(
                width: fieldWidth,
                height: fieldHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32), // Verde campo de fútbol
                  image: DecorationImage(
                    image: AssetImage('assets/grass_texture.png'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Elementos del campo (líneas, círculos, etc.)
                    _buildFootballFieldElements(fieldWidth, fieldHeight),
                    
                    // Añadir jugadores posicionados
                    ...players.map((player) {
                      final String playerId = player['id'].toString();
                      
                      // Obtener la posición o usar una por defecto
                      Offset position = positions[playerId] ?? 
                          Offset(0.5, isTeamClaro ? 0.3 : 0.7); // Posición por defecto
                      
                      // Calcular la posición en píxeles
                      final double posX = position.dx * fieldWidth;
                      final double posY = position.dy * fieldHeight;
                      
                      return Stack(
                        children: [
                          // Avatar del jugador
                          Positioned(
                            left: posX - 70,
                            top: posY - 70,
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: GestureDetector(
                                onTap: () => onPlayerTap(player, isTeamClaro),
                                child: _buildPlayerAvatar(player, posX, posY),
                              ),
                            ),
                          ),
                          
                          // Nombre del jugador
                          Positioned(
                            left: posX - 40,
                            top: posY + 30,
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTeamClaro 
                                      ? Colors.blue.shade300.withOpacity(0.5) 
                                      : Colors.red.shade300.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    player['nombre'] ?? 'Jugador',
                                    style: TextStyle(
                                      color: isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  _buildPlayerStats(player),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Construye las estadísticas del jugador para mostrar debajo del nombre
  Widget _buildPlayerStats(Map<String, dynamic> player) {
    final int goles = player['goles'] ?? 0;
    final int asistencias = player['asistencias'] ?? 0;
    
    if (goles <= 0 && asistencias <= 0) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (goles > 0) ...[
            Icon(
              Icons.sports_soccer,
              color: Colors.white70,
              size: 10,
            ),
            const SizedBox(width: 2),
            Text(
              '$goles',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (goles > 0 && asistencias > 0)
            const SizedBox(width: 8),
          if (asistencias > 0) ...[
            Icon(
              Icons.emoji_events,
              color: Colors.white70,
              size: 10,
            ),
            const SizedBox(width: 2),
            Text(
              '$asistencias',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Construye el avatar del jugador con efectos visuales
  Widget _buildPlayerAvatar(Map<String, dynamic> player, double posX, double posY) {
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
    final bool isMVP = (isTeamClaro && mvpTeamClaro == playerId) || 
                     (!isTeamClaro && mvpTeamOscuro == playerId);
    
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
              color: (isMVP && isPartidoFinalizado) ? Colors.amber : Colors.white,
              width: (isMVP && isPartidoFinalizado) ? 3 : 2,
            ),
            boxShadow: [
              if (isMVP && isPartidoFinalizado)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              BoxShadow(
                color: (isTeamClaro ? Colors.blue : Colors.red).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: const Offset(0, 2),
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
                  width: 1.5,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  average.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
        // Estrella MVP
        if (isMVP && isPartidoFinalizado)
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  /// Construye los elementos del campo de fútbol (líneas, círculos, áreas, etc.)
  Widget _buildFootballFieldElements(double width, double height) {
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
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                left: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
              ),
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
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                left: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
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
        
        // Área pequeña superior
        Positioned(
          top: 0,
          left: width * 0.3,
          child: Container(
            width: width * 0.4,
            height: height * 0.06,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                left: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
              ),
            ),
          ),
        ),
        
        // Área pequeña inferior
        Positioned(
          bottom: 0,
          left: width * 0.3,
          child: Container(
            width: width * 0.4,
            height: height * 0.06,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                left: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                right: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
              ),
            ),
          ),
        ),
        
        // Portería superior
        Positioned(
          top: -5,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        
        // Portería inferior
        Positioned(
          bottom: -5,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Obtiene el color correspondiente al promedio de habilidad del jugador
  Color _getAverageColor(double average) {
    if (average >= 90) return Colors.purple;
    if (average >= 80) return Colors.green.shade800;
    if (average >= 70) return Colors.blue.shade800;
    if (average >= 60) return Colors.orange.shade800;
    return Colors.red.shade800;
  }
}
