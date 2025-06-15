import 'package:flutter/material.dart';

/// Widget de diálogo para finalizar un partido y seleccionar un único jugador MVP
class MatchFinishDialog extends StatefulWidget {
  final Map<String, dynamic> matchData;
  final List<Map<String, dynamic>> teamClaro;
  final List<Map<String, dynamic>> teamOscuro;
  final Function(String?, String?) onFinishMatch;
  
  const MatchFinishDialog({
    Key? key,
    required this.matchData,
    required this.teamClaro,
    required this.teamOscuro,
    required this.onFinishMatch,
  }) : super(key: key);
  
  @override
  _MatchFinishDialogState createState() => _MatchFinishDialogState();
}

class _MatchFinishDialogState extends State<MatchFinishDialog> {
  String? _selectedMvpId;
  bool _isFromClaroTeam = false;
  
  @override
  void initState() {
    super.initState();
    // Inicializar con cualquier MVP previamente seleccionado
    _selectedMvpId = widget.matchData['mvp_team_claro'];
    _isFromClaroTeam = _selectedMvpId != null;
    
    if (_selectedMvpId == null) {
      _selectedMvpId = widget.matchData['mvp_team_oscuro'];
      _isFromClaroTeam = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Obtener la información actual del partido
    final int golesEquipoClaro = widget.matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = widget.matchData['resultado_oscuro'] ?? 0;
    
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
            // Título
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined, 
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Finalizar Partido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mensaje de confirmación
            const Text(
              '¿Estás seguro de que deseas finalizar el partido?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Marcador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Marcador Final',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Equipo Claro',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '$golesEquipoClaro - $golesEquipoOscuro',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Equipo Oscuro',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // MVP del Partido - Título
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'MVP del Partido:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            const Text(
              'Selecciona un jugador como el más valioso del partido',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Pestañas para seleccionar equipo
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFromClaroTeam = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isFromClaroTeam 
                            ? Colors.blue.shade700 
                            : Colors.blue.shade900,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: _isFromClaroTeam 
                              ? Colors.blue.shade300 
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Equipo Claro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFromClaroTeam = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isFromClaroTeam 
                            ? Colors.red.shade700 
                            : Colors.blue.shade900,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: !_isFromClaroTeam 
                              ? Colors.red.shade300 
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Equipo Oscuro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // MVP Selector
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topLeft: _isFromClaroTeam ? Radius.zero : Radius.circular(8),
                  topRight: !_isFromClaroTeam ? Radius.zero : Radius.circular(8),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _isFromClaroTeam 
                    ? widget.teamClaro.length 
                    : widget.teamOscuro.length,
                itemBuilder: (context, index) {
                  final player = _isFromClaroTeam 
                      ? widget.teamClaro[index] 
                      : widget.teamOscuro[index];
                  final playerId = player['id'].toString();
                  final isSelected = _selectedMvpId == playerId;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMvpId = isSelected ? null : playerId;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (_isFromClaroTeam 
                                ? Colors.blue.shade400.withOpacity(0.3)
                                : Colors.red.shade400.withOpacity(0.3))
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
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _isFromClaroTeam 
                                ? Colors.blue.shade700 
                                : Colors.red.shade700,
                            child: player['foto_perfil'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      player['foto_perfil'],
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    player['nombre'].isNotEmpty
                                        ? player['nombre'][0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              player['nombre'] ?? 'Jugador',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
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
            
            const SizedBox(height: 12),
            
            // Advertencia
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Esta acción no se puede deshacer. Asegúrate de guardar las posiciones antes de finalizar.',
                    style: TextStyle(
                      color: Colors.orange.shade100,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Finalizar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Llamar al callback para finalizar el partido
                    // Pasamos el MVP seleccionado al equipo correspondiente y null al otro
                    if (_isFromClaroTeam) {
                      widget.onFinishMatch(_selectedMvpId, null);
                    } else {
                      widget.onFinishMatch(null, _selectedMvpId);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}