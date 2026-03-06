import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<UserModel> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Better than .single() as it won't throw if not found

      if (data == null) {
        throw 'Profile not found';
      }
      return UserModel.fromJson(data);
    } catch (e, stack) {
      AppLogger.e('Error fetching profile', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    try {
      AppLogger.i('Updating profile for: ${user.id}');
      // Remove email before upsert as it's not in the public.profiles table
      final data = user.toJson();
      await _client.from('profiles').upsert(data);
      AppLogger.i('Profile updated successfully');
    } catch (e, stack) {
      AppLogger.e('Error updating profile', e, stack);
      rethrow;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      return response == null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return (data as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.e('Error searching users', e, stack);
      return [];
    }
  }

  @override
  Stream<UserModel> watchProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) {
            // This is the CRITICAL part. If the profile doesn't exist, we throw
            // so the Cubit can handle it and potentially create one.
            throw 'ProfileNotFound';
          }
          return UserModel.fromJson(data.first);
        });
  }

  @override
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _client
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      AppLogger.e('Error updating online status', e);
    }
  }
}
