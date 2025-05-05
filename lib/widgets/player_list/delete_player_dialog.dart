import 'package:flutter/material.dart';

/// Widget que muestra un diálogo de confirmación para eliminar un jugador
class DeletePlayerDialog extends StatelessWidget {
  final String playerName;
  final VoidCallback onConfirm;
  
  const DeletePlayerDialog({
    Key? key,
    required this.playerName,
    required this.onConfirm,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.indigo.shade900,
      title: const Text('Eliminar Jugador', style: TextStyle(color: Colors.white)),
      content: Text(
        '¿Estás seguro que deseas eliminar a $playerName? Esta acción no se puede deshacer.',
        style: TextStyle(color: Colors.white.withOpacity(0.8)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }

  /// Método estático para mostrar el diálogo de eliminación
  static Future<void> show({
    required BuildContext context,
    required String playerName,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => DeletePlayerDialog(
        playerName: playerName,
        onConfirm: onConfirm,
      ),
    );
  }
}
