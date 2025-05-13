import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';
import '../state/notification_state.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(supabaseClient: Supabase.instance.client);
});

final notificationControllerProvider = StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return NotificationController(notificationRepository: notificationRepository);
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationController({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(NotificationState.initial());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications = await _notificationRepository.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> createNotification(NotificationModel notification) async {
    try {
      final createdNotification = await _notificationRepository.createNotification(notification);
      
      final updatedNotifications = [...state.notifications, createdNotification];
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error creating notification: $e');
      // Don't update state for failed notification creation
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.markAsRead();
        }
        return notification;
      }).toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      
      final updatedNotifications = state.notifications.map((notification) {
        return notification.markAsRead();
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}