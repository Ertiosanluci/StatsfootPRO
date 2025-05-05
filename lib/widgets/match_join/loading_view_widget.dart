import 'package:flutter/material.dart';

/// Widget que muestra una vista de carga para la pantalla de unirse a un partido
class LoadingViewWidget extends StatelessWidget {
  final String matchId;
  
  const LoadingViewWidget({
    Key? key,
    required this.matchId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade800],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando información del partido...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            // Añadir el ID para depuración
            const SizedBox(height: 10),
            Text(
              'ID: $matchId',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
