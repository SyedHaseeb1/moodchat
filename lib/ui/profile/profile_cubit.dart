import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/logger.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/user_local_data_source.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final UserLocalDataSource _localDataSource;
  StreamSubscription? _profileSubscription;

  ProfileCubit(this._profileRepository, this._localDataSource) : super(ProfileInitial());

  void loadProfile(UserModel currentUser) {
    AppLogger.i('ProfileCubit: Loading profile for ${currentUser.id}');
    emit(ProfileLoading());
    _profileSubscription?.cancel();
    _profileSubscription = _profileRepository
        .watchProfile(currentUser.id)
        .listen(
          (user) {
            AppLogger.d('ProfileCubit: Profile loaded for ${user.id}');
            emit(ProfileLoaded(user.copyWith(email: currentUser.email)));
          },
          onError: (e) async {
            AppLogger.e('ProfileCubit: Load Error: $e');
            if (e.toString().contains('ProfileNotFound')) {
              AppLogger.i(
                'ProfileCubit: Profile not found. Attempting to create...',
              );
              try {
                await _profileRepository.updateProfile(currentUser);
                AppLogger.i('ProfileCubit: Initial row created.');
                // Stream should emit new data soon
              } catch (createError) {
                AppLogger.e('ProfileCubit: Create Error: $createError');
                emit(
                  ProfileError(
                    'Failed to create initial profile: $createError',
                  ),
                );
              }
            } else {
              emit(ProfileError(e.toString()));
            }
          },
        );
  }

  Future<void> updateFullName(String name) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        fullName: name,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updateUsername(String username) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        username: username,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updateWebsite(String url) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        website: url,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updateAvatarUrl(String url) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        avatarUrl: url,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updateBio(String bio) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        bio: bio,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updateMoodStatus(String status) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        moodStatus: status,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> updatePhoneNumber(String phone) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        phoneNumber: phone,
        updatedAt: DateTime.now(),
      );
      _performUpdate(updatedUser, currentUser);
    }
  }

  Future<void> _performUpdate(
    UserModel updatedUser,
    UserModel previousUser,
  ) async {
    try {
      emit(ProfileUpdating());
      await _profileRepository.updateProfile(updatedUser);
      // Update local storage so other screens (like Home) see the change immediately
      await _localDataSource.saveUser(updatedUser);
      // Stream in loadProfile should emit new state automatically
    } catch (e) {
      AppLogger.e('ProfileCubit: Update Error: $e');
      emit(ProfileError(e.toString()));
      emit(ProfileLoaded(previousUser));
    }
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
