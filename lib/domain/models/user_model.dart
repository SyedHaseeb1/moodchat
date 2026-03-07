import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? email; // From auth, not in profiles table
  final String? username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? website;
  final String? moodStatus;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? phoneNumber;
  final DateTime? updatedAt;

  /// Derived online status based on last_seen timestamp.
  /// Returns true if last_seen was within the last 40 seconds.
  /// Use this instead of [isOnline] when displaying other users' status.
  bool get isCurrentlyOnline {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inSeconds < 40;
  }

  const UserModel({
    required this.id,
    this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.website,
    this.bio,
    this.moodStatus,
    this.isOnline = false,
    this.lastSeen,
    this.phoneNumber,
    this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? website,
    String? bio,
    String? moodStatus,
    bool? isOnline,
    DateTime? lastSeen,
    String? phoneNumber,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      moodStatus: moodStatus ?? this.moodStatus,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, email, username, fullName, avatarUrl, website, bio, moodStatus, isOnline, lastSeen, phoneNumber, updatedAt];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      website: json['website'] as String?,
      bio: json['bio'] as String?,
      moodStatus: json['mood_status'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      phoneNumber: json['phone_number'] as String?,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'website': website,
      'bio': bio,
      'mood_status': moodStatus,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'phone_number': phoneNumber,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
