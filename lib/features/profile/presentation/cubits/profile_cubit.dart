import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/error_formatter.dart';
import '../../repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  static const _tag = 'ProfileCubit';

  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(const ProfileInitial());

  Future<void> loadProfile(String uid, {bool silent = false}) async {
    AppLogger.i(_tag, 'loadProfile: uid=$uid silent=$silent');
    final skipLoadingUi = silent &&
        state is ProfileLoaded &&
        (state as ProfileLoaded).profile.uid == uid;
    if (!skipLoadingUi) {
      emit(const ProfileLoading());
    }
    try {
      final profile = await _profileRepository.getProfile(uid);
      AppLogger.i(_tag, 'loadProfile: loaded @${profile.username}');
      emit(ProfileLoaded(profile));
    } catch (e) {
      AppLogger.e(_tag, 'loadProfile failed', e);
      emit(ProfileError(formatError(e)));
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarPath,
  }) async {
    final current = state;
    if (current is! ProfileLoaded) return;
    AppLogger.i(_tag, 'updateProfile: @${current.profile.username}');

    emit(ProfileUpdating(current.profile));
    try {
      await _profileRepository.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarPath: avatarPath,
      );
      final updated = await _profileRepository.getProfile(current.profile.uid);
      AppLogger.i(_tag, 'updateProfile: done');
      emit(ProfileLoaded(updated));
    } catch (e) {
      AppLogger.e(_tag, 'updateProfile failed', e);
      emit(ProfileError(formatError(e)));
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    AppLogger.d(_tag, 'checkUsernameAvailability: $username');
    return _profileRepository.isUsernameAvailable(username);
  }
}
