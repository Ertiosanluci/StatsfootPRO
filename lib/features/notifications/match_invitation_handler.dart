import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/notifications/domain/models/notification_model.dart';
import 'package:statsfoota/features/notifications/presentation/controllers/notification_controller.dart';

/// Widget para manejar las invitaciones a partidos
class MatchInvitationHandler extends ConsumerWidget {
  final NotificationModel notification;

  const MatchInvitationHandler({
    Key? key,
    required this.notification,
  }) : super(key: key);
  
  /// Método público para manejar la respuesta a una invitación
  Future<void> handleInvitation(BuildContext context, WidgetRef ref, bool accept) async {
    return _handleMatchInvitationResponse(context, ref, notification, accept);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo mostrar botones si es una invitación a partido y tiene resourceId
    if (notification.type != NotificationType.matchInvite || notification.resourceId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 65),
      child: Row(
        children: [
          _buildActionButton(
            label: 'Aceptar',
            color: Colors.green,
            onPressed: () => _handleMatchInvitationResponse(context, ref, notification, true),
          ),
          const SizedBox(width: 10),
          _buildActionButton(
            label: 'Rechazar',
            color: Colors.red,
            onPressed: () => _handleMatchInvitationResponse(context, ref, notification, false),
          ),
        ],
      ),
    );
  }

  /// Construye un botón de acción para aceptar o rechazar invitaciones
  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
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
          const SnackBar(content: Text('Error: No se pudo identificar el partido'))
        );
        return;
      }
      
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado'))
        );
        return;
      }
      
      // Actualizar el estado de la invitación
      final status = accept ? 'accepted' : 'declined';
      await supabase
          .from('match_invitations')
          .update({'status': status})
          .eq('match_id', matchId)
          .eq('invited_id', userId);
      
      // Si el usuario acepta, añadirlo como participante del partido
      if (accept) {
        // Verificar si ya es participante
        final existingParticipant = await supabase
            .from('match_participants')
            .select()
            .eq('match_id', matchId)
            .eq('user_id', userId)
            .maybeSingle();
        
        if (existingParticipant == null) {
          // Añadir como participante
          await supabase
              .from('match_participants')
              .insert({
                'match_id': matchId,
                'user_id': userId,
              });
        }
      }
      
      // Marcar la notificación como leída en la base de datos
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notification.id);
      
      // Actualizar el estado local y eliminar la notificación de la lista
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
      
      // Mostrar mensaje de confirmación
      Navigator.pop(context); // Cerrar el cajón de notificaciones
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Te has unido al partido' : 'Has rechazado la invitación'))
      );
      
    } catch (e) {
      debugPrint('Error al responder a la invitación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la invitación: $e'))
      );
    }
  }
}
