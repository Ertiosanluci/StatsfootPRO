import 'package:uuid/uuid.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  blocked
}

class FriendRequest {
  final String id;
  final String userId1;
  final String userId2;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      userId1: json['user_id_1'] as String,
      userId2: json['user_id_2'] as String,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id_1': userId1,
      'user_id_2': userId2,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FriendRequest.create({
    required String senderId,
    required String receiverId,
  }) {
    return FriendRequest(
      id: const Uuid().v4(),
      userId1: senderId,
      userId2: receiverId,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  static FriendRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FriendRequestStatus.pending;
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'blocked':
        return FriendRequestStatus.blocked;
      default:
        throw ArgumentError('Invalid status: $status');
    }
  }

  static String _statusToString(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'pending';
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.blocked:
        return 'blocked';
    }
  }

  FriendRequest copyWith({
    String? id,
    String? userId1,
    String? userId2,
    FriendRequestStatus? status,
    DateTime? createdAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
