class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
  });

  factory UserModel.empty({required String uid}) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      username: '',
      displayName: '',
      bio: '',
      createdAt: now,
      updatedAt: now,
      commentCount: 0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? commentCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }
}
