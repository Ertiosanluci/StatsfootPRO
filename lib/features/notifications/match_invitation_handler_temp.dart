import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  
  /// Maneja la respuesta a una solicitud de amistad (aceptar, rechazar o cancelar)
  Future<void> _handleFriendRequestResponse(BuildContext context, WidgetRef ref, NotificationModel notification, bool accept) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      _showToast("Error: Usuario no autenticado");
      _removeNotificationFromFeed(ref, notification.id);
      return;
    }

    final isSentRequest = userId == notification.senderId;

    try {
      if (isSentRequest) {
        // Es una solicitud enviada por el usuario actual (cancelar)
        final friendController = ref.read(friendControllerProvider.notifier);

        if (notification.resourceId != null) {
          await friendController.cancelFriendRequest(notification.resourceId!);
          await friendController.loadPendingRequests();
          _showToast("Solicitud de amistad cancelada");
        } else {
          // Si no hay resourceId, intentar buscar la solicitud por senderId y userId (receptor)
          final result = await supabase
              .from('friends')
              .select()
              .eq('user_id_1', userId)
              .eq('user_id_2', notification.userId)
              .eq('status', 'pending')
              .limit(1)
              .maybeSingle();
              
          if (result != null && result['id'] != null) {
            final String friendRequestId = result['id'];
            await friendController.cancelFriendRequest(friendRequestId);
            await friendController.loadPendingRequests();
            _showToast("Solicitud de amistad cancelada");
          } else {
            _showToast("Esta solicitud de amistad ya no está disponible");
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

          _showToast("Solicitud de amistad aceptada");
        } else {
          _showToast("Esta solicitud de amistad ya no está disponible");
        }
      } else {
        // Rechazar solicitud de amistad
        if (notification.resourceId != null) {
          final String resourceId = notification.resourceId!;
          await supabase
              .from('friends')
              .update({'status': 'rejected'})
              .match({'id': resourceId});

          _showToast("Solicitud de amistad rechazada");
        } else {
          _showToast("Esta solicitud de amistad ya no está disponible");
        }
      }

      // Marcar la notificación como leída
      await supabase
          .from('notifications')
          .update({'read': true})
          .match({'id': notification.id});

      // Actualizar el estado local
      _removeNotificationFromFeed(ref, notification.id);
      ref.read(friendControllerProvider.notifier).loadFriends();
    } catch (e) {
      dev.log('Error al procesar solicitud de amistad: $e');
      _showToast("Esta solicitud de amistad ya no está disponible");
      _removeNotificationFromFeed(ref, notification.id);
    }
  }

  /// Maneja la respuesta a una invitación a un partido (aceptar o rechazar)
  Future<void> _handleMatchInvitationResponse(BuildContext context, WidgetRef ref, NotificationModel notification, bool accept) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      _showToast("Error: Usuario no autenticado");
      _removeNotificationFromFeed(ref, notification.id);
      return;
    }

    // Verificar si hay un ID de partido en la notificación
    if (notification.resourceId == null) {
      _showToast("Este partido ya no está disponible.");
      _removeNotificationFromFeed(ref, notification.id);
      return;
    }

    final String matchId = notification.resourceId!;
    
    try {
      if (accept) {
        // Aceptar invitación al partido
        await supabase
            .from('match_players')
            .insert({
              'match_id': matchId,
              'player_id': userId,
              'status': 'accepted',
            });
            
        _showToast("Has aceptado unirte al partido");
      } else {
        // Rechazar invitación al partido
        await supabase
            .from('match_players')
            .insert({
              'match_id': matchId,
              'player_id': userId,
              'status': 'rejected',
            });
            
        _showToast("Has rechazado la invitación al partido");
      }

      // Marcar la notificación como leída
      await supabase
          .from('notifications')
          .update({'read': true})
          .match({'id': notification.id});

      // Actualizar el estado local
      _removeNotificationFromFeed(ref, notification.id);
    } catch (e) {
      dev.log('Error al procesar invitación a partido: $e');
      _showToast("Este partido ya no está disponible.");
      _removeNotificationFromFeed(ref, notification.id);
    }
  }
  
  /// Muestra un mensaje usando Fluttertoast
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: const Color(0xFF333333),
      textColor: Colors.white,
      fontSize: 16.0
    );
  }
  
  /// Elimina la notificación del feed local
  void _removeNotificationFromFeed(WidgetRef ref, String notificationId) {
    ref.read(notificationControllerProvider.notifier).markAsRead(notificationId);
    ref.read(notificationControllerProvider.notifier).deleteNotification(notificationId);
  }
}
