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
                // Avatar del remitente con indicador de carga
                _buildSenderAvatar(notification),
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

  // Caché de avatares para evitar múltiples consultas
  static final Map<String, String?> _avatarCache = {};
  
  // Caché de nombres para evitar múltiples consultas
  static final Map<String, String> _nameCache = {};
  
  /// Obtiene el avatar del usuario desde Supabase con caché
  Future<String?> _getUserAvatar(String? userId) async {
    if (userId == null) {
      debugPrint('DEBUG: getUserAvatar - userId es null');
      return null;
    }
    
    debugPrint('DEBUG: getUserAvatar - Buscando avatar para userId: $userId');
    
    // Si ya tenemos el avatar en caché, devolverlo inmediatamente
    if (_avatarCache.containsKey(userId)) {
      debugPrint('DEBUG: getUserAvatar - Avatar encontrado en caché: ${_avatarCache[userId]}');
      return _avatarCache[userId];
    }
    
    try {
      debugPrint('DEBUG: getUserAvatar - Consultando a Supabase');
      final supabase = Supabase.instance.client;
      
      // Consultar todos los campos para depuración
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Imprimir todos los campos de la respuesta para depuración
      debugPrint('DEBUG: getUserAvatar - Campos disponibles en la respuesta: ${response.keys.join(', ')}');
      debugPrint('DEBUG: getUserAvatar - Respuesta completa de Supabase: $response');
      
      // Intentar obtener el avatar_url (según la imagen compartida)
      String? avatarUrl;
      if (response.containsKey('avatar_url')) {
        avatarUrl = response['avatar_url'] as String?;
        debugPrint('DEBUG: getUserAvatar - URL del avatar obtenida desde avatar_url: $avatarUrl');
      } else {
        debugPrint('DEBUG: getUserAvatar - Campo avatar_url no encontrado en la respuesta');
      }
      
      // Guardar en caché para futuras consultas
      _avatarCache[userId] = avatarUrl;
      
      // También guardamos el nombre en caché
      String? fullName;
      if (response.containsKey('full_name')) {
        fullName = response['full_name'] as String?;
      } else if (response.containsKey('username')) {
        fullName = response['username'] as String?;
      }
      
      if (fullName != null && fullName.isNotEmpty) {
        _nameCache[userId] = fullName;
        debugPrint('DEBUG: getUserAvatar - Nombre guardado en caché: $fullName');
      }
      
      return avatarUrl;
    } catch (e) {
      debugPrint('ERROR: getUserAvatar - Error al obtener avatar: $e');
      // Guardar null en caché para evitar consultas repetidas que fallan
      _avatarCache[userId] = null;
      return null;
    }
  }
  
  /// Obtiene el nombre del remitente desde Supabase con caché
  Future<String> _getSenderName(String? userId) async {
    if (userId == null) return '?';
    
    // Si ya tenemos el nombre en caché, devolverlo inmediatamente
    if (_nameCache.containsKey(userId)) {
      return _nameCache[userId]!;
    }
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('username, full_name')
          .eq('id', userId)
          .single();
      
      // Preferimos el nombre completo, pero si no está disponible usamos el username
      String name = response['full_name'] as String? ?? '';
      if (name.isEmpty) {
        name = response['username'] as String? ?? '?';
      }
      
      // Guardar en caché para futuras consultas
      _nameCache[userId] = name;
      
      return name;
    } catch (e) {
      debugPrint('Error al obtener nombre: $e');
      return '?';
    }
  }

  // El método _getInitialsOrIcon ha sido eliminado ya que ahora usamos _getSenderName para obtener la inicial del remitente

  /// Construye el avatar del remitente de la notificación
  Widget _buildSenderAvatar(NotificationModel notification) {
    // Si no hay senderId, intentar extraerlo del campo data para invitaciones a partidos
    if (notification.senderId == null && notification.type == NotificationType.matchInvite) {
      debugPrint('DEBUG: _buildSenderAvatar - senderId es null, intentando extraer inviter_id del campo data');
      
      // Usar FutureBuilder para manejar la extracción asíncrona del inviter_id
      return FutureBuilder<String?>(
        future: _extractInviterIdFromData(notification),
        builder: (context, inviterIdSnapshot) {
          // Mientras se carga el inviter_id, mostrar un indicador de carga
          if (inviterIdSnapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          }
          
          // Si encontramos el inviter_id, usarlo para obtener el avatar
          if (inviterIdSnapshot.hasData && inviterIdSnapshot.data != null) {
            String inviterId = inviterIdSnapshot.data!;
            debugPrint('DEBUG: _buildSenderAvatar - Se encontró inviter_id: $inviterId');
            
            return FutureBuilder<String?>(
              future: _getUserAvatar(inviterId),
              builder: (context, avatarSnapshot) {
                if (avatarSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                }
                
                // Mostrar la foto de perfil si está disponible
                if (avatarSnapshot.hasData && avatarSnapshot.data != null && avatarSnapshot.data!.isNotEmpty) {
                  return CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: NetworkImage(avatarSnapshot.data!),
                  );
                } else {
                  // Si no hay foto, mostrar un avatar con la primera letra del nombre
                  return FutureBuilder<String>(
                    future: _getSenderName(inviterId),
                    builder: (context, nameSnapshot) {
                      String initial = '';
                      if (nameSnapshot.hasData && nameSnapshot.data!.isNotEmpty) {
                        initial = nameSnapshot.data![0].toUpperCase();
                      }
                      
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade300,
                        child: Text(
                          initial.isNotEmpty ? initial : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            );
          } else {
            // Si no se encuentra inviter_id, extraer el nombre del mensaje
            debugPrint('DEBUG: _buildSenderAvatar - No se encontró inviter_id, extrayendo nombre del mensaje');
            String senderName = _extractSenderNameFromMessage(notification.message);
            debugPrint('DEBUG: _buildSenderAvatar - Nombre extraído del mensaje: $senderName');
            
            String initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
            
            return CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade300,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            );
          }
        },
      );
    }
    
    // Si hay senderId, intentar obtener el avatar
    return FutureBuilder<String?>(
      future: _getUserAvatar(notification.senderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }
        
        // Mostrar la foto de perfil si está disponible
        if (snapshot.data != null && snapshot.data!.isNotEmpty) {
          return CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        } else {
          // Si no hay foto, mostrar un avatar con la primera letra del nombre
          return FutureBuilder<String>(
            future: _getSenderName(notification.senderId),
            builder: (context, nameSnapshot) {
              String initial = '';
              if (nameSnapshot.hasData && nameSnapshot.data!.isNotEmpty) {
                initial = nameSnapshot.data![0].toUpperCase();
              }
              
              return CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade300,
                child: Text(
                  initial.isNotEmpty ? initial : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
  
  /// Extrae el nombre del remitente del mensaje de la notificación
  String _extractSenderNameFromMessage(String message) {
    // Patrones comunes en mensajes de notificación
    if (message.contains(' te ha ')) {
      return message.split(' te ha ')[0];
    } else if (message.contains(' ha ')) {
      return message.split(' ha ')[0];
    }
    return '';
  }
  
  /// Extrae el ID del remitente desde el campo data de una notificación de invitación a partido
  Future<String?> _extractInviterIdFromData(NotificationModel notification) async {
    try {
      // Obtener el resourceId que contiene información del partido
      if (notification.resourceId == null) {
        debugPrint('DEBUG: _extractInviterIdFromData - El resourceId es nulo');
        return null;
      }
      
      // Intentar obtener el inviter_id directamente de la base de datos
      // Esto es una solución temporal hasta que se actualice la función SQL
      return await _getInviterIdFromDatabase(notification.resourceId!);
    } catch (e) {
      debugPrint('DEBUG: _extractInviterIdFromData - Error al extraer inviter_id: $e');
      return null;
    }
  }
  
  /// Obtiene el ID del invitador desde la base de datos usando el ID del partido
  Future<String?> _getInviterIdFromDatabase(String matchId) async {
    try {
      debugPrint('DEBUG: _getInviterIdFromDatabase - Buscando inviter_id para match: $matchId');
      
      // Consultar la tabla match_invitations para obtener el inviter_id
      final result = await Supabase.instance.client
          .from('match_invitations')
          .select('inviter_id')
          .eq('match_id', matchId)
          .limit(1)
          .maybeSingle();
      
      if (result != null && result['inviter_id'] != null) {
        final String inviterId = result['inviter_id'];
        debugPrint('DEBUG: _getInviterIdFromDatabase - inviter_id encontrado: $inviterId');
        return inviterId;
      } else {
        debugPrint('DEBUG: _getInviterIdFromDatabase - No se encontró inviter_id en la base de datos');
        return null;
      }
    } catch (e) {
      debugPrint('DEBUG: _getInviterIdFromDatabase - Error al consultar la base de datos: $e');
      return null;
    }
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
