import 'package:flutter/material.dart';

/// Widget que muestra el marcador del partido con los goles de cada equipo
/// y el estado del partido (finalizado o en curso)
class ScoreboardWidget extends StatelessWidget {
  final int golesEquipoClaro;
  final int golesEquipoOscuro;
  final bool isPartidoFinalizado;
  
  const ScoreboardWidget({
    Key? key,
    required this.golesEquipoClaro,
    required this.golesEquipoOscuro,
    required this.isPartidoFinalizado,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo Claro
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'EQUIPO CLARO',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Marcador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$golesEquipoClaro',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Text(
                      '$golesEquipoOscuro',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Equipo Oscuro
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'EQUIPO OSCURO',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Indicador de estado del partido
          if (isPartidoFinalizado)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PARTIDO FINALIZADO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
