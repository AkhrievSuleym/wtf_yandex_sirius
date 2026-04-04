import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile(String uid);
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    bool? isPublic,
    String? avatarPath,
  });
  Future<bool> isUsernameAvailable(String username);
}
