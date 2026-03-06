import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/friendship_repository.dart';
import '../../core/logger.dart';

abstract class FriendshipState extends Equatable {
  const FriendshipState();
  @override
  List<Object?> get props => [];
}

class FriendshipInitial extends FriendshipState {}
class FriendshipLoading extends FriendshipState {}
class FriendshipLoaded extends FriendshipState {
  final List<UserModel> friends;
  final List<Map<String, dynamic>> pendingRequests;
  const FriendshipLoaded({required this.friends, required this.pendingRequests});
  @override
  List<Object?> get props => [friends, pendingRequests];
}
class FriendshipError extends FriendshipState {
  final String message;
  const FriendshipError(this.message);
  @override
  List<Object?> get props => [message];
}

class FriendshipCubit extends Cubit<FriendshipState> {
  final FriendshipRepository _friendshipRepository;
  StreamSubscription? _friendshipSubscription;

  FriendshipCubit(this._friendshipRepository) : super(FriendshipInitial());

  void loadFriendships(String userId) {
    emit(FriendshipLoading());
    _friendshipSubscription?.cancel();
    
    // Listen for real-time updates
    _friendshipSubscription = _friendshipRepository.watchFriendships(userId).listen((_) async {
      await _refresh(userId);
    });
  }

  Future<void> _refresh(String userId) async {
    try {
      final friends = await _friendshipRepository.getFriends(userId);
      final pending = await _friendshipRepository.getPendingRequests(userId);
      emit(FriendshipLoaded(friends: friends, pendingRequests: pending));
    } catch (e) {
      emit(FriendshipError(e.toString()));
    }
  }

  Future<void> sendRequest(String userId, String friendId) async {
    try {
      await _friendshipRepository.sendFriendRequest(userId, friendId);
    } catch (e) {
      AppLogger.e('FriendshipCubit: Error sending request', e);
    }
  }

  Future<void> acceptRequest(int friendshipId) async {
    try {
      await _friendshipRepository.acceptFriendRequest(friendshipId);
    } catch (e) {
      AppLogger.e('FriendshipCubit: Error accepting request', e);
    }
  }

  Future<void> rejectRequest(int friendshipId) async {
    try {
      await _friendshipRepository.rejectFriendRequest(friendshipId);
    } catch (e) {
      AppLogger.e('FriendshipCubit: Error rejecting request', e);
    }
  }

  Future<void> addInstantFriend(String userId, String friendId) async {
    try {
      await _friendshipRepository.addInstantFriend(userId, friendId);
    } catch (e) {
      AppLogger.e('FriendshipCubit: Error adding instant friend', e);
    }
  }

  @override
  Future<void> close() {
    _friendshipSubscription?.cancel();
    return super.close();
  }
}
