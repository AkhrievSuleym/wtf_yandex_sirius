class SearchHistoryItem {
  final String query;
  final String? viewedUid;
  final String? viewedUsername;
  final String? viewedDisplayName;
  final String? viewedAvatarUrl;
  final DateTime timestamp;

  const SearchHistoryItem({
    required this.query,
    this.viewedUid,
    this.viewedUsername,
    this.viewedDisplayName,
    this.viewedAvatarUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'viewedUid': viewedUid,
        'viewedUsername': viewedUsername,
        'viewedDisplayName': viewedDisplayName,
        'viewedAvatarUrl': viewedAvatarUrl,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) =>
      SearchHistoryItem(
        query: json['query'] as String,
        viewedUid: json['viewedUid'] as String?,
        viewedUsername: json['viewedUsername'] as String?,
        viewedDisplayName: json['viewedDisplayName'] as String?,
        viewedAvatarUrl: json['viewedAvatarUrl'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
