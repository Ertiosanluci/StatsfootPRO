import 'package:flutter/material.dart';

/// Widget que muestra una tarjeta con información resumida de un partido
class MatchCardWidget extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const MatchCardWidget({
    Key? key,
    required this.match,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Procesar fecha si existe
    String formattedDate = '';
    String formattedTime = '';
    
    if (match['fecha'] != null) {
      try {
        final DateTime matchDate = DateTime.parse(match['fecha']);
        formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
        formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        debugPrint('Error al formatear fecha: $e');
      }
    }
    
    // Determinar estado y color
    final String estado = match['estado']?.toString() ?? 'pendiente';
    final Color statusColor = _getStatusColor(estado);
    
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del partido con estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match['nombre']?.toString() ?? 'Partido sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(estado),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Información básica del partido
              Row(
                children: [
                  _buildInfoItem(
                    Icons.calendar_today,
                    formattedDate.isNotEmpty ? formattedDate : 'Sin fecha',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    Icons.access_time,
                    formattedTime.isNotEmpty ? formattedTime : 'Sin hora',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    Icons.format_list_numbered,
                    match['formato']?.toString() ?? 'No especificado',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ubicación
              if (match['ubicacion'] != null && match['ubicacion'].toString().isNotEmpty)
                _buildInfoItem(
                  Icons.location_on,
                  match['ubicacion'].toString(),
                  isFullWidth: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construye un ítem de información con un icono y texto
  Widget _buildInfoItem(IconData icon, String text, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Devuelve el color asociado al estado del partido
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
      case 'en_curso':
        return Colors.green;
      case 'pendiente':
        return Colors.blue;
      case 'finalizado':
        return Colors.purple;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Devuelve el texto legible asociado al estado del partido
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
      case 'en_curso':
        return 'En curso';
      case 'pendiente':
        return 'Pendiente';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status.toUpperCase();
    }
  }
}
