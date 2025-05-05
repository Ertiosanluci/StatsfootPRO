import 'package:flutter/material.dart';

/// Widget que muestra un diálogo para finalizar un partido
/// permitiendo seleccionar MVP de cada equipo y confirmando el resultado final
class FinalizeMatchDialogWidget extends StatefulWidget {
  final int golesEquipoClaro;
  final int golesEquipoOscuro;
  final List<Map<String, dynamic>> teamClaro;
  final List<Map<String, dynamic>> teamOscuro;
  final String? mvpTeamClaro;
  final String? mvpTeamOscuro;
  final Function(String? mvpClaro, String? mvpOscuro) onFinalize;
  final VoidCallback onCancel;
  
  const FinalizeMatchDialogWidget({
    Key? key,
    required this.golesEquipoClaro,
    required this.golesEquipoOscuro,
    required this.teamClaro,
    required this.teamOscuro,
    this.mvpTeamClaro,
    this.mvpTeamOscuro,
    required this.onFinalize,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  State<FinalizeMatchDialogWidget> createState() => _FinalizeMatchDialogWidgetState();
  
  /// Método estático para mostrar el diálogo
  static Future<void> show({
    required BuildContext context,
    required int golesEquipoClaro,
    required int golesEquipoOscuro,
    required List<Map<String, dynamic>> teamClaro,
    required List<Map<String, dynamic>> teamOscuro,
    String? mvpTeamClaro,
    String? mvpTeamOscuro,
    required Function(String? mvpClaro, String? mvpOscuro) onFinalize,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return FinalizeMatchDialogWidget(
          golesEquipoClaro: golesEquipoClaro,
          golesEquipoOscuro: golesEquipoOscuro,
          teamClaro: teamClaro,
          teamOscuro: teamOscuro,
          mvpTeamClaro: mvpTeamClaro,
          mvpTeamOscuro: mvpTeamOscuro,
          onFinalize: onFinalize,
          onCancel: onCancel,
        );
      },
    );
  }
}

class _FinalizeMatchDialogWidgetState extends State<FinalizeMatchDialogWidget> {
  late String? mvpClaroLocal;
  late String? mvpOscuroLocal;
  
  @override
  void initState() {
    super.initState();
    mvpClaroLocal = widget.mvpTeamClaro;
    mvpOscuroLocal = widget.mvpTeamOscuro;
  }
  
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
            _buildScoreboardSection(),
            const SizedBox(height: 24),
            _buildMVPSelection(),
            const SizedBox(height: 24),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  /// Construye la sección del marcador 
  Widget _buildScoreboardSection() {
    return Column(
      children: [
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Equipo Claro
                  _buildTeamScore(
                    teamName: 'Equipo Claro',
                    score: widget.golesEquipoClaro,
                    isTeamClaro: true,
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Equipo Oscuro
                  _buildTeamScore(
                    teamName: 'Equipo Oscuro',
                    score: widget.golesEquipoOscuro,
                    isTeamClaro: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Construye el elemento del marcador de un equipo
  Widget _buildTeamScore({
    required String teamName,
    required int score,
    required bool isTeamClaro,
  }) {
    return Column(
      children: [
        Text(
          teamName,
          style: TextStyle(
            color: isTeamClaro ? Colors.blue.shade300 : Colors.red.shade300,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Construye la sección de selección de jugadores MVP
  Widget _buildMVPSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona los MVP del partido:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // MVP Equipo Claro
            Expanded(
              child: _buildMVPSelector(
                title: 'MVP Claro',
                teamColor: Colors.blue.shade700,
                selectedPlayerId: mvpClaroLocal,
                teamPlayers: widget.teamClaro,
                onSelect: (playerId) {
                  setState(() {
                    mvpClaroLocal = playerId;
                  });
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // MVP Equipo Oscuro
            Expanded(
              child: _buildMVPSelector(
                title: 'MVP Oscuro',
                teamColor: Colors.red.shade700,
                selectedPlayerId: mvpOscuroLocal,
                teamPlayers: widget.teamOscuro,
                onSelect: (playerId) {
                  setState(() {
                    mvpOscuroLocal = playerId;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Construye un selector de jugador MVP
  Widget _buildMVPSelector({
    required String title,
    required Color teamColor,
    required String? selectedPlayerId,
    required List<Map<String, dynamic>> teamPlayers,
    required Function(String? playerId) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: teamColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: teamColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: selectedPlayerId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: teamColor.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: teamColor.withOpacity(0.5)),
              ),
            ),
            dropdownColor: Colors.blue.shade900,
            style: const TextStyle(color: Colors.white),
            hint: const Text(
              'Selecciona jugador',
              style: TextStyle(color: Colors.white70),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Ninguno', style: TextStyle(color: Colors.white70)),
              ),
              ...teamPlayers.map((player) {
                final String playerId = player['id'].toString();
                final String playerName = player['nombre'] ?? 'Jugador';
                
                return DropdownMenuItem<String?>(
                  value: playerId,
                  child: Text(playerName, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ],
            onChanged: (value) => onSelect(value),
          ),
        ],
      ),
    );
  }
  
  /// Construye los botones de acción
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => widget.onFinalize(mvpClaroLocal, mvpOscuroLocal),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Finalizar Partido'),
        ),
      ],
    );
  }
}
