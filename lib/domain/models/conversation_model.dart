import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final DateTime createdAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String user1Id;
  final String user2Id;
  final int user1UnreadCount;
  final int user2UnreadCount;

  const ConversationModel({
    required this.id,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageAt,
    required this.user1Id,
    required this.user2Id,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessageText: json['last_message_text'] as String?,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String) 
          : null,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      user1UnreadCount: (json['user1_unread_count'] as int?) ?? 0,
      user2UnreadCount: (json['user2_unread_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'last_message_text': lastMessageText,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_unread_count': user1UnreadCount,
      'user2_unread_count': user2UnreadCount,
    };
  }

  @override
  List<Object?> get props => [
    id, createdAt, lastMessageText, lastMessageAt, 
    user1Id, user2Id, user1UnreadCount, user2UnreadCount
  ];
}
