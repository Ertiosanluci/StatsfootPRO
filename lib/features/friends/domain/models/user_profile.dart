class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final String? fieldPosition;
  final String? playFrequency;
  final String? skillLevel;
  final String? description;

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.age,
    this.gender,
    this.fieldPosition,
    this.playFrequency,
    this.skillLevel,
    this.description,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      fieldPosition: json['field_position'] as String?,
      playFrequency: json['play_frequency'] as String?,
      skillLevel: json['skill_level'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'age': age,
      'gender': gender,
      'field_position': fieldPosition,
      'play_frequency': playFrequency,
      'skill_level': skillLevel,
      'description': description,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? age,
    String? gender,
    String? fieldPosition,
    String? playFrequency,
    String? skillLevel,
    String? description,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      fieldPosition: fieldPosition ?? this.fieldPosition,
      playFrequency: playFrequency ?? this.playFrequency,
      skillLevel: skillLevel ?? this.skillLevel,
      description: description ?? this.description,
    );
  }
}
