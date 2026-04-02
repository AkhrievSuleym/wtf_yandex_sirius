import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(const ProfileInitial());

  Future<void> loadProfile(String uid) async {
    emit(const ProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(uid);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    bool? isPublic,
    String? avatarPath,
  }) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(current.profile));
    try {
      await _profileRepository.updateProfile(
        displayName: displayName,
        bio: bio,
        isPublic: isPublic,
        avatarPath: avatarPath,
      );
      // Reload updated profile
      final updated = await _profileRepository.getProfile(current.profile.uid);
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    return _profileRepository.isUsernameAvailable(username);
  }
}
