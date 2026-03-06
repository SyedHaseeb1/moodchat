import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/logger.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<UserModel?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        AppLogger.d('Auth State Changed: ${user?.email ?? 'Unauthenticated'}');
        if (user == null) return null;
        
        return UserModel(
          id: user.id,
          email: user.email,
          fullName: user.userMetadata?['full_name'],
          avatarUrl: user.userMetadata?['avatar_url'],
        );
      });

  @override
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'],
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  @override
  Future<UserModel?> signIn({required String email, required String password}) async {
    AppLogger.i('Email Sign-In attempt: $email');
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) return null;
    
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'],
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    AppLogger.i('Google Sign-In process started');
    // For Supabase to work, we MUST use the Web Client ID as the serverClientId
    final webClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID');

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.w('Google Sign-In cancelled by user');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        AppLogger.e('Failed to retrieve Google tokens');
        throw 'No Google Access Token/ID Token found.';
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user != null) {
        AppLogger.i('Google Sign-In successful for: ${user.email}');
      }
      return user != null ? UserModel(id: user.id, email: user.email ?? '') : null;
    } catch (e, stack) {
      AppLogger.e('Google Sign-In Error', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    AppLogger.i('Signing out user...');
    await _client.auth.signOut();
    await GoogleSignIn().signOut();
    AppLogger.i('Sign-out complete');
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
