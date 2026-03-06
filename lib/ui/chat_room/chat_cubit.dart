import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messageSubscription;

  ChatCubit(this._chatRepository) : super(ChatInitial());

  void loadMessages(String otherUserId) {
    emit(ChatLoading());
    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository.getMessages(otherUserId).listen(
      (messages) {
        emit(ChatLoaded(messages));
      },
      onError: (e) {
        emit(ChatError(e.toString()));
      },
    );
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      await _chatRepository.sendMessage(receiverId, content);
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
