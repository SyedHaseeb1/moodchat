import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<UserModel?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        return user != null
            ? UserModel(id: user.id, email: user.email ?? '')
            : null;
      });

  @override
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? UserModel(id: user.id, email: user.email ?? '') : null;
  }

  @override
  Future<UserModel?> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    return user != null ? UserModel(id: user.id, email: user.email ?? '') : null;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    return user != null ? UserModel(id: user.id, email: user.email ?? '') : null;
  }
}
