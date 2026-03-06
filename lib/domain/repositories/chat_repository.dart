import '../models/message_model.dart';

abstract class ChatRepository {
  Stream<List<MessageModel>> getMessages(String otherUserId);
  Future<void> sendMessage(String receiverId, String content);
  Future<void> markAsRead(String messageId);
}
