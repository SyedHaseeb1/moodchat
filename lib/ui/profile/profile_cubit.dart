import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/logger.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  StreamSubscription? _profileSubscription;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  void loadProfile(UserModel currentUser) {
    AppLogger.i('ProfileCubit: Loading profile for ${currentUser.id}');
    emit(ProfileLoading());
    _profileSubscription?.cancel();
    _profileSubscription = _profileRepository.watchProfile(currentUser.id).listen(
      (user) {
        AppLogger.d('ProfileCubit: Profile loaded for ${user.id}');
        emit(ProfileLoaded(user.copyWith(email: currentUser.email)));
      },
      onError: (e) async {
        AppLogger.e('ProfileCubit: Load Error: $e');
        if (e.toString().contains('ProfileNotFound')) {
          AppLogger.i('ProfileCubit: Profile not found. Attempting to create...');
          try {
            await _profileRepository.updateProfile(currentUser);
            AppLogger.i('ProfileCubit: Initial row created.');
            // Stream should emit new data soon
          } catch (createError) {
            AppLogger.e('ProfileCubit: Create Error: $createError');
            emit(ProfileError('Failed to create initial profile: $createError'));
          }
        } else {
          emit(ProfileError(e.toString()));
        }
      },
    );
  }

  Future<void> updateBio(String bio) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        bio: bio,
        updatedAt: DateTime.now(),
      );
      
      try {
        emit(ProfileUpdating());
        await _profileRepository.updateProfile(updatedUser);
      } catch (e) {
        emit(ProfileError(e.toString()));
        emit(ProfileLoaded(currentUser));
      }
    }
  }

  Future<void> updateMoodStatus(String status) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        moodStatus: status,
        updatedAt: DateTime.now(),
      );
      
      try {
        emit(ProfileUpdating());
        await _profileRepository.updateProfile(updatedUser);
      } catch (e) {
        emit(ProfileError(e.toString()));
        emit(ProfileLoaded(currentUser));
      }
    }
  }

  Future<void> updatePhoneNumber(String phone) async {
    if (state is ProfileLoaded) {
      final currentUser = (state as ProfileLoaded).user;
      final updatedUser = currentUser.copyWith(
        phoneNumber: phone,
        updatedAt: DateTime.now(),
      );
      
      try {
        emit(ProfileUpdating());
        await _profileRepository.updateProfile(updatedUser);
      } catch (e) {
        emit(ProfileError(e.toString()));
        emit(ProfileLoaded(currentUser));
      }
    }
  }
}
  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
