import 'package:equatable/equatable.dart';
import '../../models/profile_model.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [
        profile.uid,
        profile.displayName,
        profile.bio,
        profile.avatarUrl,
        profile.commentCount,
        profile.reactionStats,
      ];
}

class ProfileUpdating extends ProfileState {
  final ProfileModel profile;
  const ProfileUpdating(this.profile);

  @override
  List<Object?> get props => [profile.uid];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
