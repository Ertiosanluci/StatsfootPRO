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
  }  /// Construye la sección de selección de MVPs
  Widget _buildMVPSelection() {
    // Combinar los jugadores de ambos equipos
    List<Map<String, dynamic>> allPlayers = [...widget.teamClaro, ...widget.teamOscuro];
    
    // Calcular tamaño y características del grid basado en el dispositivo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Detectar si estamos en navegador web (típicamente pantallas más anchas)
    final bool isWebBrowser = screenWidth > 800;    // Ajustar parámetros según plataforma
    final int crossAxisCount = isWebBrowser ? 5 : 3; // Más columnas en web
    final double aspectRatio = isWebBrowser ? 0.85 : 0.7; // Ajustado para más espacio vertical (foto grande)
    final double maxHeightFactor = isWebBrowser ? 0.7 : 0.5; // Más espacio en web
    
    // Altura máxima ajustada
    final gridMaxHeight = screenHeight * maxHeightFactor;
    
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
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
                },                child: Container(
                  padding: EdgeInsets.all(isWebBrowser ? 3 : 4.5),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? teamColor.withOpacity(0.3)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.amber
                          : Colors.white24,
                      width: isSelected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Contenedor principal para el avatar con el indicador de equipo superpuesto
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar del jugador (ahora más grande)
                          CircleAvatar(
                            radius: isWebBrowser ? 26 : 32,
                            backgroundColor: teamColor,
                            child: player['foto_perfil'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      player['foto_perfil'],
                                      width: isWebBrowser ? 50 : 62,
                                      height: isWebBrowser ? 50 : 62,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        player['nombre']?.isNotEmpty == true 
                                            ? player['nombre'][0].toUpperCase() 
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    player['nombre']?.isNotEmpty == true 
                                        ? player['nombre'][0].toUpperCase() 
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                          ),
                          
                          // Indicador de equipo (ahora en la esquina superior derecha)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: isWebBrowser ? 8 : 12,
                              height: isWebBrowser ? 8 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: teamColor,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          
                          // Estrella si está seleccionado (ahora en la parte inferior)
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              child: Icon(
                                Icons.stars_rounded,
                                color: Colors.amber,
                                size: isWebBrowser ? 14 : 18,
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: isWebBrowser ? 4 : 6),
                      
                      // Nombre del jugador (ahora directamente debajo del avatar)
                      Text(
                        player['nombre'] ?? 'Jugador',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWebBrowser ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
