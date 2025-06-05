class MatchInvitation {
  final String id;
  final String matchId;
  final String inviterId;
  final String invitedUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final Match? match;
  final Profile? inviter;

  MatchInvitation({
    required this.id,
    required this.matchId,
    required this.inviterId,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.match,
    this.inviter,
  });

  factory MatchInvitation.fromJson(Map<String, dynamic> json) {
    return MatchInvitation(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      inviterId: json['inviter_id'] as String,
      invitedUserId: json['invited_user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null 
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      match: json['matches'] != null 
          ? Match.fromJson(json['matches'] as Map<String, dynamic>)
          : null,
      inviter: json['inviter'] != null 
          ? Profile.fromJson(json['inviter'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'inviter_id': inviterId,
      'invited_user_id': invitedUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

class Match {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String time;
  final String location;
  final int maxPlayers;
  final String creatorId;

  Match({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.maxPlayers,
    required this.creatorId,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      location: json['location'] as String,
      maxPlayers: json['max_players'] as int,
      creatorId: json['creator_id'] as String,
    );
  }
}

class Profile {
  final String id;
  final String username;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
