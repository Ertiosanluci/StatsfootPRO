import 'package:flutter/material.dart';

/// Widget que muestra un diálogo con las opciones para un jugador
class PlayerOptionsDialog extends StatelessWidget {
  final Map<String, dynamic> player;
  final VoidCallback onEdit;
  final VoidCallback onViewStats;
  final VoidCallback onDelete;
  
  const PlayerOptionsDialog({
    Key? key,
    required this.player,
    required this.onEdit,
    required this.onViewStats,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text('Editar jugador', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.white),
            title: const Text('Ver estadísticas', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onViewStats();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade300),
            title: Text('Eliminar', style: TextStyle(color: Colors.red.shade300)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  /// Método para mostrar el diálogo de opciones de jugador
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> player,
    required VoidCallback onEdit,
    required VoidCallback onViewStats,
    required VoidCallback onDelete,
  }) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerOptionsDialog(
        player: player,
        onEdit: onEdit,
        onViewStats: onViewStats,
        onDelete: onDelete,
      ),
    );
  }
}
