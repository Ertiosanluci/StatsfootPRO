import 'package:flutter/material.dart';

/// Widget que muestra una fila con una estadística de jugador,
/// incluyendo nombre, valor y barra de progreso
class StatRowWidget extends StatelessWidget {
  final String statName;
  final int value;
  
  const StatRowWidget({
    Key? key,
    required this.statName,
    required this.value,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final Color statColor = _getStatColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              "$value",
              style: TextStyle(
                color: statColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(statColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  /// Devuelve un color basado en el valor de la estadística
  Color _getStatColor(int value) {
    if (value >= 85) return Colors.green.shade500;
    if (value >= 70) return Colors.lightGreen.shade500;
    if (value >= 55) return Colors.amber.shade500;
    if (value >= 40) return Colors.orange.shade500;
    return Colors.red.shade500;
  }
}
