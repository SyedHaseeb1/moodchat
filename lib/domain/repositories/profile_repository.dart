import '../../domain/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getProfile(String userId);
  Future<void> updateProfile(UserModel user);
  Stream<UserModel> watchProfile(String userId);
}
