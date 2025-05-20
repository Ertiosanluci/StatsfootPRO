import 'package:flutter/material.dart';
import 'scrolling_text_widget.dart';

/// Widget que muestra el marcador de un partido con la puntuación de ambos equipos
/// y el estado del partido (finalizado o en curso)
class ScoreboardWidget extends StatelessWidget {
  final int golesEquipoClaro;
  final int golesEquipoOscuro;
  final bool isPartidoFinalizado;
  final String equipoClaroNombre;
  final String equipoOscuroNombre;
  final VoidCallback? onViewResultsTap;
  final bool hasCompletedVoting;  // Indica si hay una votación completada
  
  const ScoreboardWidget({
    Key? key,
    required this.golesEquipoClaro,
    required this.golesEquipoOscuro,
    required this.isPartidoFinalizado,
    this.equipoClaroNombre = 'EQUIPO CLARO',
    this.equipoOscuroNombre = 'EQUIPO OSCURO',
    this.onViewResultsTap,
    this.hasCompletedVoting = false,  // Por defecto, asumimos que no hay votación completada
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
                      equipoClaroNombre,
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
                      equipoOscuroNombre,
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
          
          // Indicador de estado del partido y texto deslizante
          if (isPartidoFinalizado) ...[
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
            if (hasCompletedVoting && onViewResultsTap != null) 
              GestureDetector(
                onTap: onViewResultsTap,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2),
                  child: ScrollingTextWidget(
                    text: '🏆 VER RESULTADOS DE VOTACIÓN 🏆',
                    duration: const Duration(seconds: 8),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    onTap: onViewResultsTap,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Widget para el marcador flotante en el campo
class FloatingScoreboard extends StatelessWidget {
  final int resultadoClaro;
  final int resultadoOscuro;
  
  const FloatingScoreboard({
    Key? key, 
    required this.resultadoClaro, 
    required this.resultadoOscuro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$resultadoClaro',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '-',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          Text(
            '$resultadoOscuro',
            style: TextStyle(
              color: Colors.red.shade300,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
