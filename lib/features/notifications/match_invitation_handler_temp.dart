import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importaciones absolutas para usar las clases existentes
import 'package:statsfoota/features/notifications/domain/models/notification_model.dart';
import 'package:statsfoota/features/notifications/presentation/controllers/notification_controller.dart' show notificationControllerProvider;
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart' show friendControllerProvider;

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
    // Procesar la acción según el tipo de notificación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notification.type == NotificationType.friendRequest) {
        _handleFriendRequestResponse(context, ref, notification, accept);
      } else if (notification.type == NotificationType.matchInvite) {
        _handleMatchInvitationResponse(context, ref, notification, accept);
      }
    });
    
    // Este widget no renderiza nada visible
    return const SizedBox.shrink();
  }

  /// Muestra un mensaje usando SnackBar de forma segura
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  /// Maneja la respuesta a una solicitud de amistad (aceptar, rechazar o cancelar)
  Future<void> _handleFriendRequestResponse(BuildContext context, WidgetRef ref, NotificationModel notification, bool accept) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        _showSnackBar(context, "Error: Usuario no autenticado", const Color(0xFFE57373));
        return;
      }

      final isSentRequest = userId == notification.senderId;

      if (isSentRequest) {
        try {
          final friendController = ref.read(friendControllerProvider.notifier);

          if (notification.resourceId != null) {
            await friendController.cancelFriendRequest(notification.resourceId!);
            await friendController.loadPendingRequests();
            
            if (context.mounted) {
              _showSnackBar(context, "Solicitud de amistad cancelada", const Color(0xFF90CAF9));
            }
          } else {
            // Si no hay resourceId, intentar buscar la solicitud por senderId y receiverId
            final result = await supabase
                .from('friends')
                .select()
                .eq('user_id_1', userId)
                .eq('user_id_2', notification.receiverId)
                .eq('status', 'pending')
                .limit(1)
                .maybeSingle();
                
            if (result != null && result['id'] != null) {
              final String friendRequestId = result['id'];
              await friendController.cancelFriendRequest(friendRequestId);
              await friendController.loadPendingRequests();
              
              if (context.mounted) {
                _showSnackBar(context, "Solicitud de amistad cancelada", const Color(0xFF90CAF9));
              }
            } else {
              if (context.mounted) {
                _showSnackBar(context, "No se pudo identificar la solicitud de amistad", const Color(0xFFE57373));
              }
            }
          }
        } catch (e) {
          dev.log('Error al cancelar solicitud de amistad: $e');
          if (context.mounted) {
            _showSnackBar(context, "Error al cancelar la solicitud: ${e.toString()}", const Color(0xFFE57373));
          }
        }
      } else if (accept) {
        // Aceptar solicitud de amistad
        if (notification.resourceId != null) {
          final String resourceId = notification.resourceId!;
          await supabase
              .from('friends')
              .update({'status': 'accepted'})
              .match({'id': resourceId});

          if (context.mounted) {
            _showSnackBar(context, "Solicitud de amistad aceptada", const Color(0xFF81C784));
          }
        }
      } else {
        // Rechazar solicitud de amistad
        if (notification.resourceId != null) {
          final String resourceId = notification.resourceId!;
          await supabase
              .from('friends')
              .update({'status': 'rejected'})
              .match({'id': resourceId});

          if (context.mounted) {
            _showSnackBar(context, "Solicitud de amistad rechazada", const Color(0xFFE57373));
          }
        }
      }

      // Marcar la notificación como leída
      await supabase
          .from('notifications')
          .update({'read': true})
          .match({'id': notification.id});

      // Actualizar el estado local
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
      ref.read(friendControllerProvider.notifier).loadFriends();
    } catch (e) {
      dev.log('Error al procesar solicitud de amistad: $e');
      if (context.mounted) {
        _showSnackBar(context, "Error al procesar la solicitud: ${e.toString()}", const Color(0xFFE57373));
      }
    }
  }

  /// Maneja la respuesta a una invitación a un partido (aceptar o rechazar)
  Future<void> _handleMatchInvitationResponse(BuildContext context, WidgetRef ref, NotificationModel notification, bool accept) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        _showSnackBar(context, "Error: Usuario no autenticado", const Color(0xFFE57373));
        return;
      }

      // Verificar si hay un ID de partido en la notificación
      if (notification.resourceId == null) {
        _showSnackBar(context, "No se pudo identificar el partido", const Color(0xFFE57373));
        return;
      }

      final String matchId = notification.resourceId!;
      
      if (accept) {
        // Aceptar invitación al partido
        await supabase
            .from('match_players')
            .insert({
              'match_id': matchId,
              'player_id': userId,
              'status': 'accepted',
            });
            
        if (context.mounted) {
          _showSnackBar(context, "Has aceptado unirte al partido", const Color(0xFF81C784));
        }
      } else {
        // Rechazar invitación al partido
        await supabase
            .from('match_players')
            .insert({
              'match_id': matchId,
              'player_id': userId,
              'status': 'rejected',
            });
            
        if (context.mounted) {
          _showSnackBar(context, "Has rechazado la invitación al partido", const Color(0xFFE57373));
        }
      }

      // Marcar la notificación como leída
      await supabase
          .from('notifications')
          .update({'read': true})
          .match({'id': notification.id});

      // Actualizar el estado local
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
    } catch (e) {
      dev.log('Error al procesar invitación a partido: $e');
      if (context.mounted) {
        _showSnackBar(context, "Error al procesar la invitación: ${e.toString()}", const Color(0xFFE57373));
      }
    }
  }
}
