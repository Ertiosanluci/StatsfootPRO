import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/notifications/domain/models/notification_model.dart';

/// Widget para mostrar una notificación con un diseño profesional
class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMatchInvite = notification.type == NotificationType.matchInvite;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.read 
              ? Colors.transparent 
              : Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar del remitente
                FutureBuilder<String?>(
                  future: _getUserAvatar(notification.senderId),
                  builder: (context, snapshot) {
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: snapshot.data != null && snapshot.data!.isNotEmpty
                          ? NetworkImage(snapshot.data!)
                          : null,
                      child: snapshot.data == null || snapshot.data!.isEmpty
                          ? _getInitialsOrIcon(notification)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),
                
                // Contenido de la notificación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: !notification.read 
                              ? Colors.black87 
                              : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Botones de acción para invitaciones a partidos
            if (isMatchInvite && onAccept != null && onReject != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 60),
                child: Row(
                  children: [
                    _buildActionButton(
                      label: 'Aceptar',
                      color: Colors.green,
                      onPressed: onAccept!,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      label: 'Rechazar',
                      color: Colors.red,
                      onPressed: onReject!,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye un botón de acción para aceptar o rechazar invitaciones
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }

  /// Obtiene el avatar del usuario desde Supabase
  Future<String?> _getUserAvatar(String? userId) async {
    if (userId == null) return null;
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      
      return response['avatar_url'] as String?;
    } catch (e) {
      debugPrint('Error al obtener avatar: $e');
      return null;
    }
  }

  /// Obtiene las iniciales del usuario o un icono según el tipo de notificación
  Widget _getInitialsOrIcon(NotificationModel notification) {
    // Si hay un mensaje que contiene un nombre, extraer las iniciales
    if (notification.message.contains(' te ha ')) {
      final parts = notification.message.split(' te ha ');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        final name = parts[0];
        final words = name.split(' ');
        String initials = '';
        
        for (var word in words) {
          if (word.isNotEmpty && initials.length < 2) {
            initials += word[0].toUpperCase();
          }
        }
        
        if (initials.isNotEmpty) {
          return Text(
            initials,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 16,
            ),
          );
        }
      }
    }
    
    // Si no se pueden extraer iniciales, mostrar un icono según el tipo
    IconData iconData;
    switch (notification.type) {
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        break;
      case NotificationType.friendAccepted:
        iconData = Icons.people;
        break;
      case NotificationType.matchInvite:
        iconData = Icons.sports_soccer;
        break;
      case NotificationType.systemNotice:
        iconData = Icons.info;
        break;
    }
    
    return Icon(iconData, color: Colors.black54, size: 24);
  }

  /// Formatea el tiempo de la notificación
  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'} atrás';
    } else {
      return 'Ahora mismo';
    }
  }
}
