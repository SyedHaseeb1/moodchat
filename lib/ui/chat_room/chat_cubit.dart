import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messageSubscription;

  ChatCubit(this._chatRepository) : super(ChatInitial());

  void loadMessages(String conversationId, String myUserId) {
    emit(ChatLoading());
    _messageSubscription?.cancel();
    
    // Mark as read when entering the chat
    _chatRepository.markAsRead(conversationId, myUserId);
    
    _messageSubscription = _chatRepository.getMessages(conversationId).listen(
      (messages) {
        emit(ChatLoaded(messages));
      },
      onError: (e) {
        emit(ChatError(e.toString()));
      },
    );
  }

  Future<void> sendMessage(String conversationId, String receiverId, String content) async {
    try {
      await _chatRepository.sendMessage(conversationId, receiverId, content);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
