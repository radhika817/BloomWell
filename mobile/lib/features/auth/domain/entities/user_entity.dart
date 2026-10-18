/// Domain entity representing the authenticated student.
class UserEntity {
  const UserEntity({
    required this.id,
    this.displayName,
    required this.role,
    required this.language,
    required this.timezone,
    required this.createdAt,
  });

  final String id;
  final String? displayName;
  final String role;
  final String language;
  final String timezone;
  final DateTime createdAt;

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'student',
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'role': role,
      'language': language,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity copyWith({
    String? id,
    String? displayName,
    String? role,
    String? language,
    String? timezone,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
