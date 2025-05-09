import 'package:flutter/material.dart';
import 'player_avatar.dart';
import 'football_field.dart';
import 'scoreboard_widget.dart';

/// Widget para mostrar la formación del equipo en el campo
class TeamFormation extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, Offset> positions;
  final bool isTeamClaro;
  final Map<String, dynamic> matchData;
  final Function(String, Offset)? onPlayerPositionChanged;
  final Function()? onSavePositions;
  final String? mvpId;
  final bool isReadOnly; // Añadir propiedad para modo de solo lectura
  final Function(Map<String, dynamic>, bool)? onPlayerTap; // Callback para cuando un jugador es tocado
  
  const TeamFormation({
    Key? key,
    required this.players,
    required this.positions,
    required this.isTeamClaro,
    required this.matchData,
    this.onPlayerPositionChanged,
    this.onSavePositions,
    this.mvpId,
    this.isReadOnly = false, // Por defecto, no está en modo de solo lectura
    this.onPlayerTap, // Nuevo callback para manejar el toque en un jugador
  }) : super(key: key);
  
  @override
  _TeamFormationState createState() => _TeamFormationState();
}

class _TeamFormationState extends State<TeamFormation> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            children: [
              // Campo de fútbol
              FootballField(width: maxWidth, height: maxHeight),
              
              // Jugadores
              ...widget.players.map((player) => _buildPlayerWidget(
                player, 
                maxWidth, 
                maxHeight,
              )),
              
              // Información sobre el equipo
              _buildTeamInfoPanel(),

              // Eliminado el marcador flotante que estaba dentro del campo
              
              // Botón para guardar posiciones
              if (!widget.isReadOnly) // Mostrar solo si no está en modo de solo lectura
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: widget.isTeamClaro ? 'savePositionsClaro' : 'savePositionsOscuro',
                    backgroundColor: widget.isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
                    mini: true,
                    child: const Icon(Icons.save, color: Colors.white),
                    onPressed: widget.onSavePositions,
                    tooltip: 'Guardar posiciones',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerWidget(Map<String, dynamic> player, double fieldWidth, double fieldHeight) {
    final String playerId = player['id'].toString();
    
    // Comprobar si el jugador tiene una posición o usar una predeterminada
    Offset position = widget.positions.containsKey(playerId)
        ? widget.positions[playerId]!
        : Offset(0.5, widget.isTeamClaro ? 0.3 : 0.7);
    
    // Convertir posición relativa (0-1) a posición en píxeles
    final double posX = position.dx * fieldWidth;
    final double posY = position.dy * fieldHeight;
    
    final bool isFinished = widget.matchData['estado'] == 'finalizado';
    final String? mvpTeamId = widget.isTeamClaro 
        ? widget.matchData['mvp_team_claro'] 
        : widget.matchData['mvp_team_oscuro'];
        
    return Positioned(
      left: posX - 25,
      top: posY - 25,
      child: Column(
        children: [
          // Avatar del jugador con Draggable
          if (!widget.isReadOnly) // Mostrar Draggable solo si no está en modo de solo lectura
            Draggable<String>(
              data: playerId,
              feedback: PlayerAvatar(
                player: player, 
                isTeamClaro: widget.isTeamClaro,
                mvpId: mvpTeamId,
                isFinished: isFinished,
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: PlayerAvatar(
                  player: player, 
                  isTeamClaro: widget.isTeamClaro,
                  mvpId: mvpTeamId,
                  isFinished: isFinished,
                ),
              ),
              onDragEnd: (details) {
                // Calcular la nueva posición relativa
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final Offset localPosition = renderBox.globalToLocal(details.offset);
                
                double newDx = localPosition.dx / fieldWidth;
                double newDy = localPosition.dy / fieldHeight;
                
                // Limitar la posición al campo
                newDx = newDx.clamp(0.0, 1.0);
                newDy = newDy.clamp(0.0, 1.0);
                
                // Actualizar posición
                widget.onPlayerPositionChanged?.call(playerId, Offset(newDx, newDy));
              },
              child: GestureDetector(
                onTap: () => _showPlayerStatsDialog(player),
                child: PlayerAvatar(
                  player: player, 
                  isTeamClaro: widget.isTeamClaro,
                  mvpId: mvpTeamId,
                  isFinished: isFinished,
                ),
              ),
            ),
          if (widget.isReadOnly) // Mostrar solo el avatar si está en modo de solo lectura
            GestureDetector(
              onTap: () => _showPlayerStatsDialog(player),
              child: PlayerAvatar(
                player: player, 
                isTeamClaro: widget.isTeamClaro,
                mvpId: mvpTeamId,
                isFinished: isFinished,
              ),
            ),
          
          // Nombre del jugador
          Container(
            width: 80,
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isTeamClaro 
                    ? Colors.blue.shade300.withOpacity(0.5) 
                    : Colors.red.shade300.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  player['nombre'] ?? 'Jugador',
                  style: TextStyle(
                    color: widget.isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((player['goles'] ?? 0) > 0 || (player['asistencias'] ?? 0) > 0)
                  Text(
                    '⚽ ${player['goles'] ?? 0} | 👟 ${player['asistencias'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamInfoPanel() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isTeamClaro ? Colors.blue.shade400 : Colors.red.shade400,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.isTeamClaro ? 'Equipo Claro' : 'Equipo Oscuro',
              style: TextStyle(
                color: widget.isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Goles: ${widget.matchData[widget.isTeamClaro ? 'resultado_claro' : 'resultado_oscuro'] ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            Text(
              'Jugadores: ${widget.players.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            // Solo mostrar instrucción de arrastrar si no está en modo de solo lectura
            if (!widget.isReadOnly)
              const Text(
                'Arrastra los jugadores para posicionar',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            // Eliminado el texto "Modo solo visualización"
          ],
        ),
      ),
    );
  }
  
  void _showPlayerStatsDialog(Map<String, dynamic> player) {
    // Llamar al callback pasado desde el componente padre
    widget.onPlayerTap?.call(player, widget.isTeamClaro);
  }
}