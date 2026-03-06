import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

  @override
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final myUserId = _client.auth.currentUser!.id;
    
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) {
          return data
              .map((json) => MessageModel.fromJson(json))
              .where((msg) =>
                  (msg.senderId == myUserId && msg.receiverId == otherUserId) ||
                  (msg.senderId == otherUserId && msg.receiverId == myUserId))
              .toList();
        });
  }

  @override
  Future<void> sendMessage(String receiverId, String content) async {
    final senderId = _client.auth.currentUser!.id;
    
    try {
      AppLogger.i('Sending message to: $receiverId');
      await _client.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      });
      AppLogger.i('Message sent successfully');
    } catch (e, stack) {
      AppLogger.e('Error sending message', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e, stack) {
      AppLogger.e('Error marking message as read', e, stack);
    }
  }
}
