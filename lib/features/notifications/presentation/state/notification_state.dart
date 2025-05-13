import '../../domain/models/notification_model.dart';

class NotificationState {
  final bool isLoading;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  factory NotificationState.initial() => const NotificationState();

  NotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}