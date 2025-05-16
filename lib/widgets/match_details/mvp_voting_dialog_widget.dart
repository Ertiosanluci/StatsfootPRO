import 'package:flutter/material.dart';

/// Widget para mostrar un diálogo de votación para MVPs
/// Permite seleccionar un MVP de cada equipo (claro y oscuro)
class MVPVotingDialog extends StatefulWidget {
  final List<Map<String, dynamic>> teamClaro;
  final List<Map<String, dynamic>> teamOscuro;
  final int matchId;
  final Function(String?, String?) onVoteSubmit;
  
  const MVPVotingDialog({
    Key? key,
    required this.teamClaro,
    required this.teamOscuro,
    required this.matchId,
    required this.onVoteSubmit,
  }) : super(key: key);
  
  @override
  _MVPVotingDialogState createState() => _MVPVotingDialogState();
}

class _MVPVotingDialogState extends State<MVPVotingDialog> {
  String? _mvpClaroId;
  String? _mvpOscuroId;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.blue.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
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
            'Votación para MVPs',
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
        'Selecciona a los mejores jugadores del partido. Puedes votar por un jugador de cada equipo.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        const Text(
          'Selecciona a los mejores jugadores:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selección del MVP del equipo claro
        _buildTeamSection(
          title: 'Equipo Claro',
          teamColor: Colors.blue.shade700,
          players: widget.teamClaro,
          selectedPlayerId: _mvpClaroId,
          onSelectPlayer: (playerId) {
            setState(() {
              _mvpClaroId = playerId;
            });
          },
        ),
        
        const SizedBox(height: 20),
        
        // Selección del MVP del equipo oscuro
        _buildTeamSection(
          title: 'Equipo Oscuro',
          teamColor: Colors.red.shade700,
          players: widget.teamOscuro,
          selectedPlayerId: _mvpOscuroId,
          onSelectPlayer: (playerId) {
            setState(() {
              _mvpOscuroId = playerId;
            });
          },
        ),
      ],
    );
  }
  
  /// Construye una sección para seleccionar el MVP de un equipo
  Widget _buildTeamSection({
    required String title,
    required Color teamColor,
    required List<Map<String, dynamic>> players,
    required String? selectedPlayerId,
    required Function(String?) onSelectPlayer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del equipo
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: teamColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: teamColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Lista horizontal de jugadores
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final playerId = player['id'].toString();
              final isSelected = selectedPlayerId == playerId;
              
              return GestureDetector(
                onTap: () {
                  onSelectPlayer(isSelected ? null : playerId);
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
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
                      // Avatar del jugador
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: teamColor,
                        child: player['foto_perfil'] != null
                            ? ClipOval(
                                child: Image.network(
                                  player['foto_perfil'],
                                  width: 36,
                                  height: 36,
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
                      const SizedBox(height: 5),
                      
                      // Nombre del jugador
                      Text(
                        player['nombre'] ?? 'Jugador',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Estrella si está seleccionado
                      if (isSelected)
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
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
    bool hasSelection = _mvpClaroId != null || _mvpOscuroId != null;
    
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
                  widget.onVoteSubmit(_mvpClaroId, _mvpOscuroId);
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
