import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/logger.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/user_local_data_source.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final UserLocalDataSource _localDataSource;

  AuthCubit(this._authRepository, this._profileRepository, this._localDataSource)
    : super(AuthInitial()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    // 1. Try to load from Local Storage first (Offline-First)
    final localUser = await _localDataSource.getUser();
    if (localUser != null) {
      AppLogger.i('AuthCubit: Found local user, emitting Authenticated (Offline-First)');
      emit(AuthAuthenticated(localUser));
    }

    // 2. Sync with Supabase in the background or foreground
    final user = _authRepository.currentUser;
    if (user != null) {
      await _handlePostAuth(user);
    } else {
      if (localUser == null) {
        emit(AuthUnauthenticated());
      } else {
        // If local user exists but Supabase says no user, they might have been signed out
        await _localDataSource.clearUser();
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<void> _handlePostAuth(UserModel user) async {
    try {
      final profile = await _profileRepository.getProfile(user.id);
      final fullUser = profile.copyWith(email: user.email);
      
      // Update online status
      await _profileRepository.updateOnlineStatus(user.id, true);
      
      // Save to local storage for offline access
      await _localDataSource.saveUser(fullUser);

      if (profile.username == null || profile.username!.isEmpty) {
        emit(AuthNeedsProfileSetup(fullUser));
      } else {
        emit(AuthAuthenticated(fullUser));
      }
    } catch (e) {
      AppLogger.e('AuthCubit: Profile fetch error', e);
      // If profile not found, it also needs setup
      if (e.toString().contains('Profile not found')) {
        emit(AuthNeedsProfileSetup(user));
      } else {
        emit(AuthAuthenticated(user)); // Fallback to basic user info
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      if (user != null) {
        await _handlePostAuth(user);
      } else {
        emit(const AuthError('Sign in failed. No user returned.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
      );
      if (user != null) {
        emit(AuthNeedsProfileSetup(user));
      } else {
        emit(const AuthError('Registration failed.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    AppLogger.d('AuthCubit: Requesting Google Sign-In');
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        AppLogger.i('AuthCubit: Google Sign-In Success');
        await _handlePostAuth(user);
      } else {
        AppLogger.w('AuthCubit: Google Sign-In returned null');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      AppLogger.e('AuthCubit: Google Sign-In Error', e);
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    final userId = getUserId();
    if (userId.isNotEmpty) {
      await _profileRepository.updateOnlineStatus(userId, false);
    }
    await _authRepository.signOut();
    await _localDataSource.clearUser();
    emit(AuthUnauthenticated());
  }

  String getUserId() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user.id;
    }
    if (state is AuthNeedsProfileSetup) {
      return (state as AuthNeedsProfileSetup).user.id;
    }
    return '';
  }
}
