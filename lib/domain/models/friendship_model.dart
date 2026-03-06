import 'package:equatable/equatable.dart';

enum FriendshipStatus { pending, accepted, blocked }

class FriendshipModel extends Equatable {
  final int? id;
  final DateTime createdAt;
  final String userId;
  final String friendId;
  final FriendshipStatus status;

  const FriendshipModel({
    this.id,
    required this.createdAt,
    required this.userId,
    required this.friendId,
    required this.status,
  });

  @override
  List<Object?> get props => [id, createdAt, userId, friendId, status];

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: FriendshipStatus.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'friend_id': friendId,
      'status': status.name,
    };
  }

  FriendshipModel copyWith({
    int? id,
    DateTime? createdAt,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
    );
  }
}
