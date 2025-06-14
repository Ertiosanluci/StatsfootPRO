import 'package:flutter/material.dart';

/// Widget de diálogo para finalizar un partido y seleccionar jugadores MVP
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
  String? _mvpClaroId;
  String? _mvpOscuroId;
  
  @override
  void initState() {
    super.initState();
    _mvpClaroId = widget.matchData['mvp_team_claro'];
    _mvpOscuroId = widget.matchData['mvp_team_oscuro'];
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
                Icon(
                  Icons.flag_outlined, 
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Finalizar Partido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Mensaje de confirmación
            Text(
              '¿Estás seguro de que deseas finalizar el partido?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            // Marcador
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
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
                  Text(
                    'Marcador Final',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
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
            
            SizedBox(height: 16),
            
            // MVP Equipo Claro - Título
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'MVP Equipo Claro:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // MVP Equipo Claro - Selector
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.teamClaro.length,
                itemBuilder: (context, index) {
                  final player = widget.teamClaro[index];
                  final playerId = player['id'].toString();
                  final isSelected = _mvpClaroId == playerId;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _mvpClaroId = isSelected ? null : playerId;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.blue.shade400.withOpacity(0.3)
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
                            backgroundColor: Colors.blue.shade700,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              player['nombre'] ?? 'Jugador',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          if (isSelected)
                            Icon(
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
            
            SizedBox(height: 16),
            
            // MVP Equipo Oscuro - Título
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'MVP Equipo Oscuro:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // MVP Equipo Oscuro - Selector
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.teamOscuro.length,
                itemBuilder: (context, index) {
                  final player = widget.teamOscuro[index];
                  final playerId = player['id'].toString();
                  final isSelected = _mvpOscuroId == playerId;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _mvpOscuroId = isSelected ? null : playerId;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.red.shade400.withOpacity(0.3)
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
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.red.shade700,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              player['nombre'] ?? 'Jugador',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          if (isSelected)
                            Icon(
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
            
            SizedBox(height: 12),
            
            // Advertencia
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                SizedBox(width: 8),
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
            
            SizedBox(height: 16),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Finalizar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Llamar al callback para finalizar el partido
                    widget.onFinishMatch(_mvpClaroId, _mvpOscuroId);
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