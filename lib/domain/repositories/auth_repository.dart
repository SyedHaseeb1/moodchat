import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signUp({required String email, required String password});
  Future<UserModel?> signIn({required String email, required String password});
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  UserModel? get currentUser;
  Stream<UserModel?> get authStateChanges;
}
