import 'package:flutter/material.dart';

/// Widget que contiene los botones de acción para la lista de jugadores
class PlayerActionButtons extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onAddPlayer;
  
  const PlayerActionButtons({
    Key? key,
    required this.onRefresh,
    required this.onAddPlayer,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón de actualización
          FloatingActionButton(
            onPressed: onRefresh,
            heroTag: 'refresh',
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar lista",
          ),
          const SizedBox(width: 16),
          // Botón principal para añadir
          FloatingActionButton.extended(
            onPressed: onAddPlayer,
            heroTag: 'add',
            backgroundColor: Colors.orange.shade600,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              "Añadir Jugador",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            elevation: 8,
          ),
        ],
      ),
    );
  }
}
