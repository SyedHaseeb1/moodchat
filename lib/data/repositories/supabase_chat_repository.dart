import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((data) {
          final messages = data.map((json) => MessageModel.fromJson(json)).toList();
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(String conversationId, String receiverId, String content) async {
    final senderId = _client.auth.currentUser!.id;
    final now = DateTime.now().toIso8601String();

    try {
      // 1. Insert Message
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      });

      // 2. Update Conversation (Last Message & Unread Count)
      // We need to know if I am user1 or user2 to increment the *other* person's unread count
      final convData = await _client
          .from('conversations')
          .select('user1_id, user1_unread_count, user2_unread_count')
          .eq('id', conversationId)
          .single();

      final bool isUser1 = convData['user1_id'] == senderId;
      final updates = {
        'last_message_text': content,
        'last_message_at': now,
        if (isUser1)
          'user2_unread_count': ((convData['user2_unread_count'] as int?) ?? 0) + 1
        else
          'user1_unread_count': ((convData['user1_unread_count'] as int?) ?? 0) + 1,
      };

      await _client.from('conversations').update(updates).eq('id', conversationId);
    } catch (e, stack) {
      AppLogger.e('Error sending message', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      final convData = await _client
          .from('conversations')
          .select('user1_id')
          .eq('id', conversationId)
          .single();

      final bool isUser1 = convData['user1_id'] == userId;
      final updates = {
        if (isUser1) 'user1_unread_count': 0 else 'user2_unread_count': 0,
      };

      await _client.from('conversations').update(updates).eq('id', conversationId);
      
      // Also mark messages where I am receiver as read
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId);
          
    } catch (e, stack) {
      AppLogger.e('Error marking as read', e, stack);
    }
  }

  @override
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((data) {
          final conversations = data
              .map((json) => ConversationModel.fromJson(json))
              .where((conv) => conv.user1Id == userId || conv.user2Id == userId)
              .toList();
          
          conversations.sort((a, b) {
            final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // Newest first
          });
          
          return conversations;
        });
  }

  @override
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    // Ensure consistent ordering for unique constraint
    final id1 = userId1.compareTo(userId2) < 0 ? userId1 : userId2;
    final id2 = userId1.compareTo(userId2) < 0 ? userId2 : userId1;

    try {
      final data = await _client
          .from('conversations')
          .select('id')
          .eq('user1_id', id1)
          .eq('user2_id', id2)
          .maybeSingle();

      if (data != null) return data['id'] as String;

      final res = await _client.from('conversations').insert({
        'user1_id': id1,
        'user2_id': id2,
      }).select('id').single();

      return res['id'] as String;
    } catch (e, stack) {
      AppLogger.e('Error getting/creating conversation', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> triggerInstantNavigation(String targetUserId) async {
    final myId = _client.auth.currentUser!.id;
    try {
      await _client.from('instant_navigation').insert({
        'trigger_user_id': myId,
        'target_user_id': targetUserId,
      });
    } catch (e, stack) {
      AppLogger.e('Error triggering instant nav', e, stack);
    }
  }

  @override
  Stream<String?> watchInstantNavigation() {
    final myId = _client.auth.currentUser!.id;
    return _client
        .from('instant_navigation')
        .stream(primaryKey: ['id'])
        .eq('target_user_id', myId)
        .map((data) {
          // Filter for non-consumed records locally since stream only supports one .eq()
          final pending = data.where((row) => row['is_consumed'] == false).toList();
          if (pending.isEmpty) return null;
          return pending.first['trigger_user_id'] as String;
        });
  }

  @override
  Future<void> consumeInstantNavigation(String targetUserId) async {
    final myId = _client.auth.currentUser!.id;
    try {
      await _client
          .from('instant_navigation')
          .update({'is_consumed': true})
          .eq('trigger_user_id', targetUserId) // triggerUserId is the one who scanned me
          .eq('target_user_id', myId);
    } catch (e, stack) {
      AppLogger.e('Error consuming instant nav', e, stack);
    }
  }
}
