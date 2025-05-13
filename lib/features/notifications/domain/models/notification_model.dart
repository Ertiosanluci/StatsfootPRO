import 'package:uuid/uuid.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  matchInvite,
  systemNotice
}

class NotificationModel {
  final String id;
  final String userId;  // The user who should receive the notification
  final String? senderId; // The user who triggered the notification (optional)
  final NotificationType type;
  final String title;
  final String message;
  final String? resourceId; // Reference to related resource (e.g., friend request ID)
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.resourceId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      senderId: json['sender_id'] as String?,
      type: _typeFromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      resourceId: json['resource_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sender_id': senderId,
      'type': _typeToString(type),
      'title': title,
      'message': message,
      'resource_id': resourceId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  // Helper method to create a friend request notification
  static NotificationModel createFriendRequestNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String requestId,
  }) {
    return NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      senderId: senderId,
      type: NotificationType.friendRequest,
      title: 'Nueva solicitud de amistad',
      message: '$senderName te ha enviado una solicitud de amistad',
      resourceId: requestId,
      createdAt: DateTime.now(),
    );
  }

  // Helper method to create a friend accepted notification
  static NotificationModel createFriendAcceptedNotification({
    required String userId,
    required String friendId,
    required String friendName,
  }) {
    return NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      senderId: friendId,
      type: NotificationType.friendAccepted,
      title: 'Solicitud aceptada',
      message: '$friendName ha aceptado tu solicitud de amistad',
      createdAt: DateTime.now(),
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'friend_accepted':
        return NotificationType.friendAccepted;
      case 'match_invite':
        return NotificationType.matchInvite;
      case 'system_notice':
        return NotificationType.systemNotice;
      default:
        throw ArgumentError('Invalid notification type: $type');
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return 'friend_request';
      case NotificationType.friendAccepted:
        return 'friend_accepted';
      case NotificationType.matchInvite:
        return 'match_invite';
      case NotificationType.systemNotice:
        return 'system_notice';
    }
  }

  // Create a copy of this notification with certain fields updated
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? senderId,
    NotificationType? type,
    String? title,
    String? message,
    String? resourceId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      resourceId: resourceId ?? this.resourceId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Mark this notification as read
  NotificationModel markAsRead() {
    return copyWith(isRead: true);
  }
}