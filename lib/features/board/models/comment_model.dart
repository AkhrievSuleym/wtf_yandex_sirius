class CommentModel {
  final String id;
  final String boardOwnerId;
  final String? authorId;
  final String text;
  final DateTime createdAt;
  final Map<String, int> reactions;
  final Map<String, List<String>> reactedBy;
  final bool isRead;
  final int replyCount;

  const CommentModel({
    required this.id,
    required this.boardOwnerId,
    this.authorId,
    required this.text,
    required this.createdAt,
    required this.reactions,
    required this.reactedBy,
    required this.isRead,
    this.replyCount = 0,
  });

  static const List<String> reactionKeys = [
    'fire',
    'heart',
    'laugh',
    'poop',
    'clown',
  ];

  static Map<String, int> get emptyReactions =>
      {for (final k in reactionKeys) k: 0};

  static Map<String, List<String>> get emptyReactedBy =>
      {for (final k in reactionKeys) k: <String>[]};

  static String emojiFor(String key) {
    switch (key) {
      case 'fire':
        return '🔥';
      case 'heart':
        return '❤️';
      case 'laugh':
        return '😂';
      case 'poop':
        return '💩';
      case 'clown':
        return '🤡';
      default:
        return '';
    }
  }

  bool hasReacted(String reactionKey, String userId) =>
      reactedBy[reactionKey]?.contains(userId) ?? false;

  CommentModel copyWith({
    String? id,
    String? boardOwnerId,
    String? authorId,
    String? text,
    DateTime? createdAt,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactedBy,
    bool? isRead,
    int? replyCount,
  }) {
    return CommentModel(
      id: id ?? this.id,
      boardOwnerId: boardOwnerId ?? this.boardOwnerId,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      reactedBy: reactedBy ?? this.reactedBy,
      isRead: isRead ?? this.isRead,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  static Map<String, int> _mergeReactions(Map? raw) {
    final m = Map<String, int>.from(emptyReactions);
    if (raw != null) {
      raw.forEach((k, v) {
        final key = k as String;
        if (v is int) {
          m[key] = v;
        } else if (v is num) {
          m[key] = v.toInt();
        }
      });
    }
    return m;
  }

  static Map<String, List<String>> _mergeReactedBy(Map<String, dynamic>? raw) {
    final m = Map<String, List<String>>.fromEntries(
      reactionKeys.map((k) => MapEntry(k, <String>[])),
    );
    if (raw != null) {
      raw.forEach((k, v) {
        final key = k as String;
        m[key] = List<String>.from(v as List? ?? []);
      });
    }
    return m;
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final rawReactedBy =
        (json['reactedBy'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return CommentModel(
      id: json['id'] as String,
      boardOwnerId: json['boardOwnerId'] as String,
      authorId: json['authorId'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reactions: _mergeReactions(json['reactions'] as Map?),
      reactedBy: _mergeReactedBy(rawReactedBy),
      isRead: json['isRead'] as bool? ?? false,
      replyCount: json['replyCount'] as int? ?? 0,
    );
  }
}
