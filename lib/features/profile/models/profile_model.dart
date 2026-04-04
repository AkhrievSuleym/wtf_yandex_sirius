import '../../../core/utils/avatar_url.dart';
import '../../board/models/comment_model.dart';

class ProfileModel {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final int commentCount;
  final bool isPublic;
  final Map<String, int> reactionStats;

  ProfileModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    required this.commentCount,
    required this.isPublic,
    Map<String, int>? reactionStats,
  }) : reactionStats = reactionStats ?? _emptyReactionStats();

  static Map<String, int> _emptyReactionStats() => Map<String, int>.fromEntries(
        CommentModel.reactionKeys.map((k) => MapEntry(k, 0)),
      );

  static Map<String, int> _parseReactionStats(Object? raw) {
    final base = _emptyReactionStats();
    if (raw is Map) {
      for (final e in raw.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is int) {
          base[k] = v;
        } else if (v is num) {
          base[k] = v.toInt();
        }
      }
    }
    return base;
  }

  ProfileModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? commentCount,
    bool? isPublic,
    Map<String, int>? reactionStats,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      commentCount: commentCount ?? this.commentCount,
      isPublic: isPublic ?? this.isPublic,
      reactionStats: reactionStats ?? Map<String, int>.from(this.reactionStats),
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        uid: json['uid'] as String,
        username: json['username'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        avatarUrl: resolveAvatarUrl(json['avatarUrl'] as String?),
        commentCount: json['commentCount'] as int? ?? 0,
        isPublic: json['isPublic'] as bool? ?? true,
        reactionStats: _parseReactionStats(json['reactionStats']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'commentCount': commentCount,
        'isPublic': isPublic,
        'reactionStats': reactionStats,
      };
}
