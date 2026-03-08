import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/logger.dart';

abstract class HandshakeState {}
class HandshakeInitial extends HandshakeState {}
class HandshakeReceived extends HandshakeState {
  final String triggerUserId;
  HandshakeReceived(this.triggerUserId);
}

class HandshakeCubit extends Cubit<HandshakeState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _navSubscription;

  HandshakeCubit(this._chatRepository) : super(HandshakeInitial());

  void startListening() {
    _navSubscription?.cancel();
    _navSubscription = _chatRepository.watchInstantNavigation().listen(
      (triggerUserId) {
        if (triggerUserId != null) {
          AppLogger.i('HandshakeCubit: Received instant navigation trigger from $triggerUserId');
          emit(HandshakeReceived(triggerUserId));
        }
      },
      onError: (e) => AppLogger.e('HandshakeCubit: Error watching instant nav', e),
    );
  }

  Future<void> consume(String triggerUserId) async {
    await _chatRepository.consumeInstantNavigation(triggerUserId);
    emit(HandshakeInitial());
  }

  @override
  Future<void> close() {
    _navSubscription?.cancel();
    return super.close();
  }
}
