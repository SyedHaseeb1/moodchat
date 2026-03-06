import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../domain/models/friendship_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/friendship_repository.dart';

class SupabaseFriendshipRepository implements FriendshipRepository {
  final SupabaseClient _client;

  SupabaseFriendshipRepository(this._client);

  @override
  Future<void> sendFriendRequest(String userId, String friendId) async {
    try {
      await _client.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': FriendshipStatus.pending.name,
      });
    } catch (e, stack) {
      AppLogger.e('Error sending friend request', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> acceptFriendRequest(int friendshipId) async {
    try {
      await _client.from('friendships').update({
        'status': FriendshipStatus.accepted.name,
      }).eq('id', friendshipId);
    } catch (e, stack) {
      AppLogger.e('Error accepting friend request', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> rejectFriendRequest(int friendshipId) async {
    try {
      await _client.from('friendships').delete().eq('id', friendshipId);
    } catch (e, stack) {
      AppLogger.e('Error rejecting friend request', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> addInstantFriend(String userId, String friendId) async {
    try {
      // For QR scan, we instantly create an accepted relationship
      // We might want to check if it already exists
      await _client.from('friendships').upsert({
        'user_id': userId,
        'friend_id': friendId,
        'status': FriendshipStatus.accepted.name,
      }, onConflict: 'user_id, friend_id');
      
      // Also add the reverse if we want bidirectional without complex queries
      // Actually, for instant add, let's keep it simple: one row 'accepted'
      // But search/list needs to handle both directions.
    } catch (e, stack) {
      AppLogger.e('Error adding instant friend', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      // Find all accepted friendships where user is participant
      // We'll fetch friendship data and the *other* person's profile
      final data = await _client
          .from('friendships')
          .select('user_id, friend_id, status, sender:profiles!user_id(*), receiver:profiles!friend_id(*)')
          .or('user_id.eq.$userId,friend_id.eq.$userId')
          .eq('status', FriendshipStatus.accepted.name);
      
      final List friendships = data as List;
      final List<UserModel> friends = [];
      
      for (var f in friendships) {
        if (f['user_id'] == userId) {
          // I sent it, the friend is the receiver
          if (f['receiver'] != null) {
            friends.add(UserModel.fromJson(f['receiver']));
          }
        } else {
          // I received it, the friend is the sender
          if (f['sender'] != null) {
            friends.add(UserModel.fromJson(f['sender']));
          }
        }
      }
      
      return friends;
    } catch (e, stack) {
      AppLogger.e('Error fetching friends', e, stack);
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    try {
      final data = await _client
          .from('friendships')
          .select('*, profiles!user_id(*)')
          .eq('friend_id', userId)
          .eq('status', FriendshipStatus.pending.name);
      
      return data as List<Map<String, dynamic>>;
    } catch (e, stack) {
      AppLogger.e('Error fetching pending requests', e, stack);
      return [];
    }
  }

  @override
  Future<FriendshipStatus?> getRelationshipStatus(String userId, String friendId) async {
    try {
      final data = await _client
          .from('friendships')
          .select('status')
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId))')
          .maybeSingle();
      
      if (data == null) return null;
      return FriendshipStatus.values.byName(data['status']);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchFriendships(String userId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter locally because .or() isn't supported on .stream()
          return data.where((row) => 
            row['user_id'] == userId || row['friend_id'] == userId
          ).toList();
        });
  }
}
