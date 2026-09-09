import 'package:flutter/foundation.dart';

@immutable
class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isPro;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isPro = true,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'isPro': isPro,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
      };

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String? ?? 'ProCut Creator',
        avatarUrl: json['avatarUrl'] as String?,
        isPro: json['isPro'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? isPro,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPro: isPro ?? this.isPro,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);
}
