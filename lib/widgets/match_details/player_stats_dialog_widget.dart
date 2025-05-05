import 'package:flutter/material.dart';

/// Widget que muestra un diálogo con estadísticas de un jugador
/// y permite modificarlas durante un partido
class PlayerStatsDialogWidget extends StatefulWidget {
  final Map<String, dynamic> player;
  final bool isTeamClaro;
  final Function(int goles, int asistencias, int golesPropios) onUpdateStats;
  
  const PlayerStatsDialogWidget({
    Key? key,
    required this.player,
    required this.isTeamClaro,
    required this.onUpdateStats,
  }) : super(key: key);
  
  @override
  State<PlayerStatsDialogWidget> createState() => _PlayerStatsDialogWidgetState();
  
  /// Método estático para mostrar el diálogo
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> player,
    required bool isTeamClaro,
    required Function(int goles, int asistencias, int golesPropios) onUpdateStats,
  }) {
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return PlayerStatsDialogWidget(
            player: player,
            isTeamClaro: isTeamClaro,
            onUpdateStats: onUpdateStats,
          );
        },
      ),
    );
  }
}

class _PlayerStatsDialogWidgetState extends State<PlayerStatsDialogWidget> {
  late int goles;
  late int asistencias;
  late int golesPropios;
  
  @override
  void initState() {
    super.initState();
    goles = widget.player['goles'] ?? 0;
    asistencias = widget.player['asistencias'] ?? 0;
    golesPropios = widget.player['goles_propios'] ?? 0;
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
            _buildDialogHeader(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  /// Construye el encabezado del diálogo con avatar y nombre del jugador
  Widget _buildDialogHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: widget.isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
          radius: 20,
          child: widget.player['foto_perfil'] != null
            ? ClipOval(
                child: Image.network(
                  widget.player['foto_perfil'],
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    widget.player['nombre'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : Text(
                widget.player['nombre'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.player['nombre'] ?? 'Jugador',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  /// Construye la tarjeta con los controles de estadísticas
  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Goles
            _buildStatRow(
              icon: Icons.sports_soccer,
              label: 'Goles',
              value: goles,
              onDecrease: goles > 0 ? () => setState(() => goles--) : null,
              onIncrease: () => setState(() => goles++),
            ),
            
            const Divider(height: 24),
            
            // Asistencias
            _buildStatRow(
              icon: Icons.emoji_events,
              label: 'Asistencias',
              value: asistencias,
              onDecrease: asistencias > 0 ? () => setState(() => asistencias--) : null,
              onIncrease: () => setState(() => asistencias++),
            ),
            
            const Divider(height: 24),
            
            // Goles en propia puerta
            _buildStatRow(
              icon: Icons.sports_soccer,
              label: 'Goles propia',
              value: golesPropios,
              onDecrease: golesPropios > 0 ? () => setState(() => golesPropios--) : null,
              onIncrease: () => setState(() => golesPropios++),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye una fila para una estadística individual con botones + y -
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required int value,
    required VoidCallback? onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              child: IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
                onPressed: onDecrease,
              ),
            ),
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green,
                onPressed: onIncrease,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Construye los botones de acción (guardar y cancelar)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            widget.onUpdateStats(goles, asistencias, golesPropios);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isTeamClaro ? Colors.blue.shade600 : Colors.red.shade600,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
