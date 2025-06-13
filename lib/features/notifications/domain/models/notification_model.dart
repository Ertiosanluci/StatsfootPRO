import 'package:uuid/uuid.dart';
import 'dart:convert';

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
  final bool read;
  final Map<String, dynamic>? data; // Datos adicionales de la notificación

  const NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.resourceId,
    required this.createdAt,
    this.read = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Determinar el tipo de notificación
    final notificationType = _typeFromString(json['type'] as String);
    
    // Procesar el campo data
    Map<String, dynamic>? notificationData;
    if (json['data'] != null) {
      notificationData = json['data'] is String 
          ? Map<String, dynamic>.from(jsonDecode(json['data'] as String)) 
          : Map<String, dynamic>.from(json['data'] as Map);
    }
    
    // Extraer resourceId según el tipo de notificación
    String? resourceId;
    if (notificationType == NotificationType.matchInvite && notificationData != null) {
      // Para invitaciones a partidos, el resourceId es el match_id en el campo data
      resourceId = notificationData['match_id']?.toString();
    } else {
      // Para otros tipos, usar el campo resource_id directamente
      resourceId = json['resource_id'] as String?;
    }
    
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      senderId: json['sender_id'] as String?,
      type: notificationType,
      title: json['title'] as String,
      message: json['message'] as String,
      resourceId: resourceId,
      createdAt: DateTime.parse(json['created_at'] as String),
      read: json['read'] as bool? ?? false,
      data: notificationData,
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
      'read': read,
      'data': data,
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
      case 'match_invitation':
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
    bool? read,
    Map<String, dynamic>? data,
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
      data: data ?? this.data,
      read: read ?? this.read,
    );
  }

  // Mark this notification as read
  NotificationModel markAsRead() {
    return copyWith(read: true);
  }
}