import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final int commentCount;
  final bool isPublic;

  const ProfileModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    required this.commentCount,
    required this.isPublic,
  });

  ProfileModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? commentCount,
    bool? isPublic,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      commentCount: commentCount ?? this.commentCount,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'commentCount': commentCount,
        'isPublic': isPublic,
      };

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        uid: json['uid'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        commentCount: json['commentCount'] as int? ?? 0,
        isPublic: json['isPublic'] as bool? ?? true,
      );

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel.fromJson(data);
  }

  factory ProfileModel.fromFavoritesDoc(Map<String, dynamic> data) {
    return ProfileModel(
      uid: data['favoriteUid'] as String,
      username: data['username'] as String,
      displayName: data['displayName'] as String,
      bio: '',
      avatarUrl: data['avatarUrl'] as String?,
      commentCount: 0,
      isPublic: true,
    );
  }
}
