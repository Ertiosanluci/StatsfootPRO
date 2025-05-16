import 'package:flutter/material.dart';
import '../widgets/match_details/mvp_voting_history_widget.dart';

/// Pantalla para mostrar el historial completo de votaciones de MVP para un partido
class MVPVotingHistoryScreen extends StatelessWidget {
  final int matchId;
  final String matchName;
  
  const MVPVotingHistoryScreen({
    Key? key,
    required this.matchId,
    required this.matchName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Votaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              matchName,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.indigo.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Todas las votaciones para MVP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Descripción
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Este historial muestra todas las votaciones de MVP que se han realizado para este partido, junto con sus resultados.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Divisor
              Divider(
                color: Colors.white.withOpacity(0.3),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              
              // Widget de historial de votaciones
              MVPVotingHistoryWidget(matchId: matchId),
            ],
          ),
        ),
      ),
    );
  }
}
