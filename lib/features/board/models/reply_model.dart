class ReplyModel {
  final String id;
  final String commentId;
  final String? ownerUid;
  final String text;
  final DateTime createdAt;

  const ReplyModel({
    required this.id,
    required this.commentId,
    this.ownerUid,
    required this.text,
    required this.createdAt,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      id: json['id'] as String,
      commentId: json['commentId'] as String,
      ownerUid: json['ownerUid'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
