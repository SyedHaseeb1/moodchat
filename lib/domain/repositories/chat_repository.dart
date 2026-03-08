import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRepository {
  // Messages
  Stream<List<MessageModel>> getMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String receiverId, String content);
  Future<void> markAsRead(String conversationId, String userId);

  // Conversations
  Stream<List<ConversationModel>> watchConversations(String userId);
  Future<String> getOrCreateConversation(String userId1, String userId2);

  // Instant Navigation (Handshake)
  Future<void> triggerInstantNavigation(String targetUserId);
  Stream<String?> watchInstantNavigation();
  Future<void> consumeInstantNavigation(String triggerUserId);
}
