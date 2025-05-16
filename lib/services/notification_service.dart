import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Clase de servicios para manejar las notificaciones en la aplicación
class NotificationService {
  final SupabaseClient supabase = Supabase.instance.client;
  
  /// Envía una notificación a todos los participantes de un partido
  Future<bool> notifyMatchParticipants({
    required int matchId, 
    required String title, 
    required String message,
    String? actionType,
  }) async {
    try {
      // 1. Obtener todos los participantes del partido
      final participants = await supabase
          .from('match_participants')
          .select('user_id')
          .eq('match_id', matchId);
      
      if (participants == null || participants.isEmpty) {
        print('No se encontraron participantes para notificar');
        return false;
      }
      
      // 2. Extraer los IDs de usuario de los participantes
      final List<String> userIds = participants
          .map<String>((p) => p['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      
      if (userIds.isEmpty) {
        print('No hay IDs de usuario válidos para notificar');
        return false;
      }
      
      // 3. Crear notificaciones en la base de datos para cada usuario
      final currentTime = DateTime.now().toIso8601String();
      
      for (String userId in userIds) {
        await supabase.from('notifications').insert({
          'user_id': userId,
          'title': title,
          'message': message,
          'match_id': matchId,
          'action_type': actionType,
          'created_at': currentTime,
          'is_read': false,
        });
      }
      
      return true;
    } catch (e) {
      print('Error al enviar notificaciones: $e');
      return false;
    }
  }
  
  /// Marca una notificación como leída
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      return false;
    }
  }
  
  /// Obtiene las notificaciones no leídas para el usuario actual
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];
      
      final notifications = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
          
      return notifications;
    } catch (e) {
      print('Error al obtener notificaciones: $e');
      return [];
    }
  }
  
  /// Muestra una notificación en la interfaz
  void showNotification(BuildContext context, String title, String message, {
    Color backgroundColor = Colors.blue,
    VoidCallback? onTap,
  }) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      action: onTap != null ? SnackBarAction(
        label: 'Ver',
        textColor: Colors.white,
        onPressed: onTap,
      ) : null,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
