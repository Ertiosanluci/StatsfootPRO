import 'package:flutter/material.dart';

/// Diálogo para mostrar y editar las estadísticas del jugador
class PlayerStatsDialog extends StatefulWidget {
  final Map<String, dynamic> player;
  final bool isTeamClaro;
  final Function(dynamic, int, int, int) onStatsUpdated;
  
  const PlayerStatsDialog({
    Key? key, 
    required this.player, 
    required this.isTeamClaro,
    required this.onStatsUpdated,
  }) : super(key: key);
  
  @override
  _PlayerStatsDialogState createState() => _PlayerStatsDialogState();
}

class _PlayerStatsDialogState extends State<PlayerStatsDialog> {
  late int _goles;
  late int _asistencias;
  late int _golesPropios;
  
  @override
  void initState() {
    super.initState();
    _goles = widget.player['goles'] ?? 0;
    _asistencias = widget.player['asistencias'] ?? 0;
    _golesPropios = widget.player['goles_propios'] ?? 0;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con avatar
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
                  radius: 20,
                  child: widget.player['foto_perfil'] != null
                      ? ClipOval(
                          child: Image.network(
                            widget.player['foto_perfil'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          widget.player['nombre']?.isNotEmpty == true
                              ? widget.player['nombre'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.player['nombre'] ?? 'Jugador',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tarjeta de estadísticas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Goles
                    _buildStatCounter(
                      label: 'Goles',
                      value: _goles,
                      icon: Icons.sports_soccer,
                      color: Colors.green,
                      onIncrement: () => setState(() => _goles++),
                      onDecrement: () => setState(() {
                        if (_goles > 0) _goles--;
                      }),
                    ),
                    
                    const Divider(),
                    
                    // Asistencias
                    _buildStatCounter(
                      label: 'Asistencias',
                      value: _asistencias,
                      icon: Icons.front_hand,
                      color: Colors.blue,
                      onIncrement: () => setState(() => _asistencias++),
                      onDecrement: () => setState(() {
                        if (_asistencias > 0) _asistencias--;
                      }),
                    ),
                    
                    const Divider(),
                    
                    // Goles propios
                    _buildStatCounter(
                      label: 'Goles en propia',
                      value: _golesPropios,
                      icon: Icons.back_hand,
                      color: Colors.red,
                      onIncrement: () => setState(() => _golesPropios++),
                      onDecrement: () => setState(() {
                        if (_golesPropios > 0) _golesPropios--;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Guardar'),
                  onPressed: () {
                    // Actualizar estadísticas y cerrar
                    widget.onStatsUpdated(
                      widget.player['id'],
                      _goles,
                      _asistencias,
                      _golesPropios,
                    );
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
  
  Widget _buildStatCounter({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      children: [
        // Icono
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Nombre de la estadística
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Controles
        Row(
          children: [
            // Botón de decremento
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
              color: Colors.grey.shade700,
            ),
            
            // Valor actual
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Botón de incremento
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}