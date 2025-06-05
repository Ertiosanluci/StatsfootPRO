import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabaseClient;

  NotificationRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return response.map<NotificationModel>((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      throw Exception('Failed to get notifications: $e');
    }
  }

  Future<NotificationModel> createNotification(NotificationModel notification) async {
    try {
      await _supabaseClient
          .from('notifications')
          .insert(notification.toJson());
      
      return notification;
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseClient
          .from('notifications')
          .update({'read': true})
          .eq('user_id', currentUserId)
          .eq('read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }
}