import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/notifications/domain/models/notification_model.dart';
import 'dart:convert';

// Caché para avatares y nombres de usuarios
final Map<String, String?> _avatarCache = {};
final Map<String, String> _nameCache = {};

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
                      // Usamos un FutureBuilder para mostrar el mensaje con el nombre del invitador
                      FutureBuilder<String>(
                        future: _buildNotificationMessage(notification),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? notification.message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          );
                        },
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
      dev.log('DEBUG: getUserAvatar - userId es null');
      return null;
    }
    
    dev.log('DEBUG: getUserAvatar - Buscando avatar para userId: $userId');
    
    // Si ya tenemos el avatar en caché, devolverlo inmediatamente
    if (_avatarCache.containsKey(userId)) {
      dev.log('DEBUG: getUserAvatar - Avatar encontrado en caché: ${_avatarCache[userId]}');
      return _avatarCache[userId];
    }
    
    try {
      dev.log('DEBUG: getUserAvatar - Consultando a Supabase');
      final supabase = Supabase.instance.client;
      
      // Consultar todos los campos para depuración
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Imprimir todos los campos de la respuesta para depuración
      dev.log('DEBUG: getUserAvatar - Campos disponibles en la respuesta: ${response.keys.join(', ')}');
      dev.log('DEBUG: getUserAvatar - Respuesta completa de Supabase: $response');
      
      // Intentar obtener el avatar_url (según la imagen compartida)
      String? avatarUrl;
      if (response.containsKey('avatar_url')) {
        avatarUrl = response['avatar_url'] as String?;
        dev.log('DEBUG: getUserAvatar - URL del avatar obtenida desde avatar_url: $avatarUrl');
      } else {
        dev.log('DEBUG: getUserAvatar - Campo avatar_url no encontrado en la respuesta');
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
        dev.log('DEBUG: getUserAvatar - Nombre guardado en caché: $fullName');
      }
      
      return avatarUrl;
    } catch (e) {
      dev.log('ERROR: getUserAvatar - Error al obtener avatar: $e');
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
      dev.log('Error al obtener nombre: $e');
      return '?';
    }
  }

  // El método _getInitialsOrIcon ha sido eliminado ya que ahora usamos _getSenderName para obtener la inicial del remitente

  /// Construye el avatar del remitente de la notificación
  Widget _buildSenderAvatar(NotificationModel notification) {
    // Si no hay senderId, intentar extraerlo del campo data para invitaciones a partidos
    if (notification.senderId == null && notification.type == NotificationType.matchInvite) {
      dev.log('DEBUG: _buildSenderAvatar - senderId es null, intentando extraer inviter_id del campo data');
      
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
            dev.log('DEBUG: _buildSenderAvatar - Se encontró inviter_id: $inviterId');
            
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
            dev.log('DEBUG: _buildSenderAvatar - No se encontró inviter_id, extrayendo nombre del mensaje');
            String senderName = _extractSenderNameFromMessage(notification.message);
            dev.log('DEBUG: _buildSenderAvatar - Nombre extraído del mensaje: $senderName');
            
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
      // Intentar obtener el inviter_id del campo data si está disponible
      if (notification.data != null && notification.data is Map) {
        final data = notification.data as Map<String, dynamic>;
        if (data.containsKey('inviter_id')) {
          dev.log('DEBUG: _extractInviterIdFromData - Encontrado inviter_id en data: ${data['inviter_id']}');
          return data['inviter_id'].toString();
        }
      }
      
      // Si no está en data, obtener el resourceId que contiene información del partido
      if (notification.resourceId == null) {
        dev.log('DEBUG: _extractInviterIdFromData - El resourceId es nulo');
        return null;
      }
      
      // Intentar obtener el inviter_id directamente de la base de datos
      // Esto es una solución temporal hasta que se actualice la función SQL
      return await _getInviterIdFromDatabase(notification.resourceId!);
    } catch (e) {
      dev.log('DEBUG: _extractInviterIdFromData - Error al extraer inviter_id: $e');
      return null;
    }
  }
  
  // El método _buildMessageWidget ya no es necesario porque usamos FutureBuilder directamente en el árbol de widgets
  
  /// Construye el mensaje de la notificación, incluyendo el nombre del invitador si está disponible
  Future<String> _buildNotificationMessage(NotificationModel notification) async {
    // Solo procesamos notificaciones de invitación a partidos
    if (notification.type != NotificationType.matchInvite) {
      return notification.message;
    }
    
    try {
      String inviterName = "";
      
      // Intentar obtener el nombre del invitador directamente de los datos adicionales
      if (notification.data != null && notification.data is Map) {
        final data = notification.data as Map<String, dynamic>;
        if (data.containsKey('inviter_name') && data['inviter_name'] != null) {
          inviterName = data['inviter_name'].toString();
          dev.log('DEBUG: _buildNotificationMessage - Nombre del invitador encontrado en data: $inviterName');
        }
      }
      
      // Si no encontramos el nombre en los datos adicionales, intentamos obtenerlo del senderId o inviter_id
      if (inviterName.isEmpty) {
        String? inviterId = notification.senderId;
        
        // Si no hay senderId, intentamos extraerlo de los datos
        if (inviterId == null) {
          inviterId = await _extractInviterIdFromData(notification);
        }
        
        // Si tenemos un ID, intentamos obtener el nombre desde la caché o la base de datos
        if (inviterId != null) {
          if (_nameCache.containsKey(inviterId)) {
            inviterName = _nameCache[inviterId]!;
            dev.log('DEBUG: _buildNotificationMessage - Nombre del invitador encontrado en caché: $inviterName');
          } else {
            // Consultar el nombre desde la base de datos
            final supabase = Supabase.instance.client;
            try {
              final response = await supabase
                .from('profiles')
                .select('username, full_name')
                .eq('id', inviterId)
                .maybeSingle();
                
              if (response != null) {
                if (response['full_name'] != null && response['full_name'].toString().isNotEmpty) {
                  inviterName = response['full_name'];
                } else if (response['username'] != null) {
                  inviterName = response['username'];
                }
                
                if (inviterName.isNotEmpty) {
                  _nameCache[inviterId] = inviterName;
                  dev.log('DEBUG: _buildNotificationMessage - Nombre del invitador obtenido de la BD: $inviterName');
                }
              }
            } catch (e) {
              dev.log('ERROR: _buildNotificationMessage - Error al consultar perfil: $e');
            }
          }
        }
      }
      
      // Si encontramos el nombre del invitador, lo incluimos en el mensaje
      if (inviterName.isNotEmpty) {
        return "$inviterName te ha invitado a un partido de fútbol. Pulsa para ver los detalles.";
      }
      
      // Si no pudimos obtener el nombre, devolvemos el mensaje original
      return notification.message;
    } catch (e) {
      dev.log('ERROR: _buildNotificationMessage - Error al construir mensaje: $e');
      return notification.message;
    }
  }
  
  /// Obtiene el ID del invitador desde la base de datos usando el ID del partido
  Future<String?> _getInviterIdFromDatabase(String matchId) async {
    try {
      dev.log('DEBUG: _getInviterIdFromDatabase - Buscando inviter_id para match: $matchId');
      
      // Consultar la tabla match_invitations para obtener el inviter_id
      final result = await Supabase.instance.client
          .from('match_invitations')
          .select('inviter_id')
          .eq('match_id', matchId)
          .limit(1)
          .maybeSingle();
      
      if (result != null && result['inviter_id'] != null) {
        final String inviterId = result['inviter_id'];
        dev.log('DEBUG: _getInviterIdFromDatabase - inviter_id encontrado: $inviterId');
        return inviterId;
      } else {
        dev.log('DEBUG: _getInviterIdFromDatabase - No se encontró inviter_id en la base de datos');
        return null;
      }
    } catch (e) {
      dev.log('DEBUG: _getInviterIdFromDatabase - Error al consultar la base de datos: $e');
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
