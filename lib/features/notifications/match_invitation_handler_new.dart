import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo simple para notificaciones
class NotificationModel {
  final String id;
  final String? type;
  final String? resourceId;
  final Map<String, dynamic>? data;
  
  const NotificationModel({
    required this.id,
    this.type,
    this.resourceId,
    this.data,
  });
}

/// Controlador para gestionar notificaciones
class NotificationController extends StateNotifier<List<NotificationModel>> {
  NotificationController() : super([]);
  
  void markAsRead(String notificationId) {
    dev.log('Marcando notificación como leída: $notificationId');
    // Aquí iría la implementación real
  }
  
  void deleteNotification(String notificationId) {
    dev.log('Eliminando notificación: $notificationId');
    // Aquí iría la implementación real
  }
}

/// Controlador para gestionar amigos
class FriendController extends StateNotifier<List<dynamic>> {
  FriendController() : super([]);
  
  void loadFriends() {
    dev.log('Recargando lista de amigos');
    // Aquí iría la implementación real
  }
}

/// Providers para los controladores
final notificationControllerProvider = StateNotifierProvider<NotificationController, List<NotificationModel>>(
  (ref) => NotificationController()
);

final friendControllerProvider = StateNotifierProvider<FriendController, List<dynamic>>(
  (ref) => FriendController()
);

/// Widget para manejar las invitaciones a partidos y solicitudes de amistad
class MatchInvitationHandler extends ConsumerWidget {
  final NotificationModel notification;
  final bool accept;

  const MatchInvitationHandler({
    Key? key,
    required this.notification,
    required this.accept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determinar el tipo de notificación y procesarla adecuadamente
    if (notification.type == 'match_invitation') {
      _handleMatchInvitationResponse(context, ref, notification, accept);
    } else if (notification.type == 'friend_request') {
      _handleFriendRequestResponse(context, ref, notification, accept);
    }
    
    // Este widget no renderiza nada visible
    return const SizedBox.shrink();
  }
  
  /// Maneja la respuesta a una solicitud de amistad (aceptar, rechazar o cancelar)
  Future<void> _handleFriendRequestResponse(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    bool accept
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final requestId = notification.resourceId;
      
      if (userId == null || requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Usuario no autenticado o solicitud inválida"),
            backgroundColor: Color(0xFFE57373),
          )
        );
        return;
      }
      
      // Verificar si la notificación es de una solicitud enviada o recibida
      final isSentRequest = notification.data?['sent_by_current_user'] == true;
      
      if (isSentRequest) {
        // Si es una solicitud enviada por el usuario actual, cancelarla
        await supabase
            .from('friends')
            .delete()
            .eq('id', requestId);
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Solicitud de amistad cancelada"),
            backgroundColor: Color(0xFF81C784),
          )
        );
      } else {
        // Si es una solicitud recibida, aceptarla o rechazarla
        if (accept) {
          // Aceptar la solicitud
          await supabase
              .from('friends')
              .update({'status': 'accepted'})
              .eq('id', requestId);
              
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Solicitud de amistad aceptada"),
              backgroundColor: Color(0xFF81C784),
            )
          );
        } else {
          // Rechazar la solicitud
          await supabase
              .from('friends')
              .update({'status': 'rejected'})
              .eq('id', requestId);
              
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Solicitud de amistad rechazada"),
              backgroundColor: Color(0xFFE57373),
            )
          );
        }
      }
      
      // Marcar la notificación como leída y eliminarla localmente
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notification.id);
      
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
      
      // Actualizar la lista de amigos
      ref.read(friendControllerProvider.notifier).loadFriends();
      
    } catch (e) {
      dev.log('Error al responder a la solicitud de amistad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al procesar la solicitud"),
          backgroundColor: Color(0xFFE57373),
        )
      );
    }
  }

  /// Maneja la respuesta a una invitación de partido (aceptar o rechazar)
  Future<void> _handleMatchInvitationResponse(
    BuildContext context, 
    WidgetRef ref,
    NotificationModel notification, 
    bool accept
  ) async {
    try {
      final matchId = notification.resourceId;
      if (matchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Partido borrado o no encontrado"),
            backgroundColor: Color(0xFFE57373),
          )
        );
        return;
      }
      
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Usuario no autenticado"),
            backgroundColor: Color(0xFFE57373),
          )
        );
        return;
      }
      
      final matchExists = await supabase
          .from('matches')
          .select('id')
          .eq('id', matchId)
          .maybeSingle();
          
      if (matchExists == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Partido borrado o no encontrado"),
            backgroundColor: Color(0xFFE57373),
          )
        );
        
        await supabase
            .from('notifications')
            .update({'read': true})
            .eq('id', notification.id);
        
        // Actualizar el estado local
        ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
        ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
        
        return;
      }
      
      final status = accept ? 'accepted' : 'declined';
      
      await supabase
          .from('match_invitations')
          .update({'status': status})
          .eq('match_id', matchId)
          .eq('invited_id', userId);
          
      if (accept) {
        final existingParticipant = await supabase
            .from('match_participants')
            .select()
            .eq('match_id', matchId)
            .eq('user_id', userId)
            .maybeSingle();
            
        if (existingParticipant == null) {
          await supabase
              .from('match_participants')
              .insert({
                'match_id': matchId,
                'user_id': userId,
              });
        }
      }
      
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notification.id);
      
      // Actualizar el estado local y eliminar la notificación de la lista
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Te has unido al partido' : 'Has rechazado la invitación'),
          backgroundColor: const Color(0xFF81C784),
        )
      );
      
      if (accept) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          '/match_details',
          arguments: matchId,
        );
      }
    } catch (e) {
      dev.log('Error al responder a la invitación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al procesar la invitación"),
          backgroundColor: Color(0xFFE57373),
        )
      );
    }
  }
}
