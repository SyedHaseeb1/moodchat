import '../models/friendship_model.dart';
import '../models/user_model.dart';

abstract class FriendshipRepository {
  Future<void> sendFriendRequest(String userId, String friendId);
  Future<void> acceptFriendRequest(int friendshipId);
  Future<void> rejectFriendRequest(int friendshipId);
  Future<void> addInstantFriend(String userId, String friendId);
  
  // Fetches current friends with their profile info
  Future<List<UserModel>> getFriends(String userId);
  
  // Fetches pending requests sent TO the user
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId);

  // Checks the relationship status between two users
  Future<FriendshipStatus?> getRelationshipStatus(String userId, String friendId);

  Stream<List<Map<String, dynamic>>> watchFriendships(String userId);
}
