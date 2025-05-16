import 'package:flutter/material.dart';

/// Widget para mostrar un diálogo de votación para MVP
/// Permite seleccionar al mejor jugador del partido de ambos equipos
class MVPVotingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> teamClaro;
  final List<Map<String, dynamic>> teamOscuro;
  final int matchId;
  final Function(String?, String?) onVoteSubmit; // Mantenemos la misma firma por compatibilidad
  final String? previousVotedPlayerId; // Jugador previamente votado por el usuario
  
  const MVPVotingDialog({
    Key? key,
    required this.teamClaro,
    required this.teamOscuro,
    required this.matchId,
    required this.onVoteSubmit,
    this.previousVotedPlayerId,
  }) : super(key: key);
  
  @override
  _MVPVotingDialogState createState() => _MVPVotingDialogState();
}

class _MVPVotingDialogState extends State<MVPVotingDialog> {
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    // Inicializar con el voto previo si existe
    if (widget.previousVotedPlayerId != null) {
      _selectedPlayerId = widget.previousVotedPlayerId;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.blue.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(),
              const SizedBox(height: 16),
              _buildExplanation(),
              const SizedBox(height: 20),
              _buildMVPSelection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construye el encabezado del diálogo
  Widget _buildDialogHeader() {
    return Row(
      children: [
        Icon(Icons.how_to_vote, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Votación para MVP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Construye la explicación del diálogo
  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      width: double.infinity,
      child: const Text(
        'Selecciona al mejor jugador del partido. Los 3 más votados serán reconocidos como los MVPs.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        softWrap: true,
      ),
    );
  }
  /// Construye la sección de selección de MVPs
  Widget _buildMVPSelection() {
    // Combinar los jugadores de ambos equipos
    List<Map<String, dynamic>> allPlayers = [...widget.teamClaro, ...widget.teamOscuro];
    
    // Calcular altura máxima para el grid (para evitar overflow)
    final screenHeight = MediaQuery.of(context).size.height;
    final gridMaxHeight = screenHeight * 0.5; // Limitar a 50% de la altura de la pantalla
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        const Text(
          'Selecciona al mejor jugador:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Contenedor con scroll para el grid de jugadores
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: gridMaxHeight,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final player = allPlayers[index];
              final playerId = player['id'].toString();
              final isSelected = _selectedPlayerId == playerId;
              final isTeamClaro = widget.teamClaro.any((p) => p['id'].toString() == playerId);
              final teamColor = isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlayerId = isSelected ? null : playerId;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? teamColor.withOpacity(0.3)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.amber
                          : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Indicador de equipo
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teamColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Avatar del jugador
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: teamColor,
                        child: player['foto_perfil'] != null
                            ? ClipOval(
                                child: Image.network(
                                  player['foto_perfil'],
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    player['nombre']?.isNotEmpty == true 
                                        ? player['nombre'][0].toUpperCase() 
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                player['nombre']?.isNotEmpty == true 
                                    ? player['nombre'][0].toUpperCase() 
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Nombre del jugador
                      Expanded(
                        child: Text(
                          player['nombre'] ?? 'Jugador',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Estrella si está seleccionado
                      if (isSelected)
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  /// Construye los botones de acción (votar/cancelar)
  Widget _buildActionButtons() {
    bool hasSelection = _selectedPlayerId != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: hasSelection
              ? () {
                  // Determinamos a qué equipo pertenece el jugador seleccionado
                  final isTeamClaro = widget.teamClaro.any((p) => p['id'].toString() == _selectedPlayerId);
                  final playerTeam = isTeamClaro ? 'claro' : 'oscuro';
                  
                  // Enviamos el ID del jugador seleccionado y su equipo
                  widget.onVoteSubmit(_selectedPlayerId, playerTeam);
                  
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Enviar Voto'),
        ),
      ],
    );
  }
}
