import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String boardOwnerId;
  final String? authorId;
  final String text;
  final DateTime createdAt;
  final Map<String, int> reactions;
  final Map<String, List<String>> reactedBy;
  final bool isRead;

  const CommentModel({
    required this.id,
    required this.boardOwnerId,
    this.authorId,
    required this.text,
    required this.createdAt,
    required this.reactions,
    required this.reactedBy,
    required this.isRead,
  });

  static const List<String> reactionKeys = ['fire', 'heart', 'laugh'];

  static Map<String, int> get emptyReactions => {
        'fire': 0,
        'heart': 0,
        'laugh': 0,
      };

  static Map<String, List<String>> get emptyReactedBy => {
        'fire': [],
        'heart': [],
        'laugh': [],
      };

  static String emojiFor(String key) {
    switch (key) {
      case 'fire':
        return '🔥';
      case 'heart':
        return '❤️';
      case 'laugh':
        return '😂';
      default:
        return '';
    }
  }

  bool hasReacted(String reactionKey, String userId) {
    return reactedBy[reactionKey]?.contains(userId) ?? false;
  }

  CommentModel copyWith({
    String? id,
    String? boardOwnerId,
    String? authorId,
    String? text,
    DateTime? createdAt,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactedBy,
    bool? isRead,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boardOwnerId': boardOwnerId,
      'authorId': authorId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'reactedBy': reactedBy.map((k, v) => MapEntry(k, v)),
      'isRead': isRead,
    };
  }

  factory CommentModel.fromJson(String id, Map<String, dynamic> json) {
    final rawReactedBy = json['reactedBy'] as Map<String, dynamic>? ?? {};

    return CommentModel(
      id: id,
      boardOwnerId: json['boardOwnerId'] as String,
      authorId: json['authorId'] as String?,
      text: json['text'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      reactions: Map<String, int>.from(json['reactions'] as Map? ?? emptyReactions),
      reactedBy: rawReactedBy.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel.fromJson(doc.id, data);
  }
}
