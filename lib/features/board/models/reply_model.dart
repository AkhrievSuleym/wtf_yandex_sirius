import '../../../core/utils/avatar_url.dart';

class ReplyModel {
  final String id;
  final String commentId;
  final String? ownerUid;
  final String? ownerAvatarUrl;
  final String text;
  final DateTime createdAt;

  const ReplyModel({
    required this.id,
    required this.commentId,
    this.ownerUid,
    this.ownerAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['ownerAvatarUrl'];
    return ReplyModel(
      id: json['id'] as String,
      commentId: json['commentId'] as String,
      ownerUid: json['ownerUid'] as String?,
      ownerAvatarUrl: rawAvatar is String ? resolveAvatarUrl(rawAvatar) : null,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
