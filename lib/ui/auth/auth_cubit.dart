import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/logger.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(email: email, password: password);
      if (user != null) {
        emit(AuthAuthenticated(user));
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
      final user = await _authRepository.signUp(email: email, password: password);
      if (user != null) {
        emit(AuthAuthenticated(user));
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
        emit(AuthAuthenticated(user));
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
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
}
