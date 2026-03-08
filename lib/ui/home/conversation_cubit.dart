import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/logger.dart';

abstract class ConversationState {}
class ConversationInitial extends ConversationState {}
class ConversationLoading extends ConversationState {}
class ConversationLoaded extends ConversationState {
  final List<ConversationModel> conversations;
  ConversationLoaded(this.conversations);
}
class ConversationError extends ConversationState {
  final String message;
  ConversationError(this.message);
}

class ConversationCubit extends Cubit<ConversationState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _subscription;

  ConversationCubit(this._chatRepository) : super(ConversationInitial());

  void loadConversations(String userId) {
    emit(ConversationLoading());
    _subscription?.cancel();
    _subscription = _chatRepository.watchConversations(userId).listen(
      (convs) {
        emit(ConversationLoaded(convs));
      },
      onError: (e) {
        AppLogger.e('ConversationCubit: Error watching conversations', e);
        emit(ConversationError(e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
