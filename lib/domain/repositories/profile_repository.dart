import '../../domain/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getProfile(String userId);
  Future<void> updateProfile(UserModel user);
  Stream<UserModel> watchProfile(String userId);
  Future<bool> isUsernameAvailable(String username);
  Future<List<UserModel>> searchUsers(String query);
  Future<void> updateOnlineStatus(String userId, bool isOnline);

  /// Lightweight heartbeat — only updates last_seen, no boolean flag.
  /// Called by [PresenceService] every 30 seconds.
  Future<void> updateLastSeen(String userId);
}
