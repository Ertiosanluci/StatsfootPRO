import 'package:flutter/material.dart';
import '../field/football_field_elements.dart';
import '../player/player_avatar_widget.dart';

/// Widget que muestra la formación completa de un equipo en el campo de fútbol
class TeamFormationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, Offset> positions;
  final bool isTeamClaro;
  final String? mvpPlayerId;
  final bool isFinished;
  final Function(Map<String, dynamic>) onPlayerTap;
  
  const TeamFormationWidget({
    Key? key,
    required this.players,
    required this.positions,
    required this.isTeamClaro,
    required this.mvpPlayerId,
    required this.isFinished,
    required this.onPlayerTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
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
                    FootballFieldElements(
                      width: fieldWidth,
                      height: fieldHeight,
                      isTeamA: isTeamClaro,
                    ),
                    
                    // Añadir jugadores posicionados
                    ...players.map((player) {
                      final String playerId = player['id'].toString();
                      
                      // Obtener la posición o usar una por defecto
                      Offset position = positions[playerId] ?? 
                          Offset(0.5, isTeamClaro ? 0.3 : 0.7); // Posición por defecto
                      
                      // Calcular la posición en píxeles
                      final double posX = position.dx * fieldWidth;
                      final double posY = position.dy * fieldHeight;
                      
                      final bool isMVP = mvpPlayerId == playerId;
                      
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
                                onTap: () => onPlayerTap(player),
                                child: Center(
                                  child: PlayerAvatarWidget(
                                    player: player,
                                    isTeamA: isTeamClaro,
                                    posX: posX,
                                    posY: posY,
                                    isMVP: isMVP,
                                    isFinished: isFinished,
                                  ),
                                ),
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
                                  
                                  // Mostrar estadísticas si tiene goles o asistencias
                                  if ((player['goles'] ?? 0) > 0 || 
                                      (player['asistencias'] ?? 0) > 0 || 
                                      (player['goles_propios'] ?? 0) > 0)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if ((player['goles'] ?? 0) > 0)
                                          _buildStatBadge(
                                            '${player['goles']}G', 
                                            Colors.green.shade300
                                          ),
                                        if ((player['asistencias'] ?? 0) > 0)
                                          _buildStatBadge(
                                            '${player['asistencias']}A', 
                                            Colors.blue.shade300
                                          ),
                                        if ((player['goles_propios'] ?? 0) > 0)
                                          _buildStatBadge(
                                            '${player['goles_propios']}GP', 
                                            Colors.red.shade300
                                          ),
                                      ],
                                    ),
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
  
  /// Crea un badge para mostrar una estadística del jugador
  Widget _buildStatBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
