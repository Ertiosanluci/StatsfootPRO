import 'package:flutter/material.dart';

/// Widget que muestra una fila editable para una estadística de jugador
/// con un slider para modificar su valor
class EditableStatRowWidget extends StatelessWidget {
  final String statName;
  final double statValue;
  final ValueChanged<double> onChanged;

  const EditableStatRowWidget({
    Key? key,
    required this.statName,
    required this.statValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Nombre de la estadística
          Expanded(
            flex: 2,
            child: Text(
              _getShortStatName(statName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          // Slider para editar el valor
          Expanded(
            flex: 5,
            child: Slider(
              value: statValue,
              min: 0,
              max: 100,
              onChanged: onChanged,
              activeColor: Colors.orange.shade600,
              inactiveColor: Colors.white70,
              thumbColor: Colors.orange.shade600,
            ),
          ),
          // Valor numérico de la estadística
          Expanded(
            flex: 1,
            child: Text(
              '${statValue.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Método para acortar el nombre de la estadística
  String _getShortStatName(String statName) {
    switch (statName) {
      case 'Tiro':
        return 'TIRO';
      case 'Regate':
        return 'REG';
      case 'Técnica':
        return 'TEC';
      case 'Defensa':
        return 'DEF';
      case 'Velocidad':
        return 'VEL';
      case 'Aguante':
        return 'AGU';
      case 'Control':
        return 'CTL';
      default:
        return statName;
    }
  }
}
