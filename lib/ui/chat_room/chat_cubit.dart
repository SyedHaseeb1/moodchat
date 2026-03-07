import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messageSubscription;

  String? _activeConversationId;
  String? _myUserId;

  ChatCubit(this._chatRepository) : super(ChatInitial());

  void loadMessages(String conversationId, String myUserId) {
    _activeConversationId = conversationId;
    _myUserId = myUserId;

    emit(ChatLoading());
    _messageSubscription?.cancel();

    _messageSubscription = _chatRepository
        .getMessages(conversationId)
        .listen(
          (messages) {
            // SAFETY CHECK
            if (_activeConversationId != conversationId) return;

            emit(ChatLoaded(messages));

            final hasUnread = messages.any(
              (m) =>
                  m.receiverId == _myUserId &&
                  !m.isRead &&
                  m.conversationId == _activeConversationId,
            );

            if (hasUnread) {
              _chatRepository.markAsRead(_activeConversationId!, _myUserId!);
            }
          },
          onError: (e) {
            emit(ChatError(e.toString()));
          },
        );

    // Mark as read once when entering the chat
    _chatRepository.markAsRead(conversationId, myUserId);
  }

  Future<void> sendMessage(
    String conversationId,
    String receiverId,
    String content,
  ) async {
    try {
      await _chatRepository.sendMessage(conversationId, receiverId, content);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _activeConversationId = null;
    return super.close();
  }
  void clearActiveChat() {
    _activeConversationId = null;
    _myUserId = null;
    _messageSubscription?.cancel();
  }
}
