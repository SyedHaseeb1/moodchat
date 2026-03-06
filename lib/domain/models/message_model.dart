import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String? conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      conversationId: json['conversation_id'] as String?,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: (json['is_read'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (conversationId != null) 'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
    };
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, receiverId, content, createdAt, isRead];
}
