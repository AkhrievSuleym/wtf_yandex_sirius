import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/board/models/comment_model.dart';

class CommentCacheDb {
  static const _dbName = 'comment_cache.db';
  static const _dbVersion = 1;
  static const _table = 'comments';
  static const _cacheSize = 10;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    return openDatabase(
      _dbName,
      version: _dbVersion,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id TEXT NOT NULL,
          owner_id TEXT NOT NULL,
          position INTEGER NOT NULL,
          json TEXT NOT NULL,
          PRIMARY KEY (id)
        )
      '''),
    );
  }

  Future<List<CommentModel>> loadComments(String ownerId) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'position ASC',
    );
    return rows
        .map((r) => CommentModel.fromJson(
            jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveComments(String ownerId, List<CommentModel> comments) async {
    final db = await _database;
    final trimmed = comments.length > _cacheSize
        ? comments.sublist(0, _cacheSize)
        : comments;

    await db.transaction((txn) async {
      await txn.delete(_table, where: 'owner_id = ?', whereArgs: [ownerId]);
      for (var i = 0; i < trimmed.length; i++) {
        final c = trimmed[i];
        await txn.insert(_table, {
          'id': c.id,
          'owner_id': ownerId,
          'position': i,
          'json': jsonEncode(_commentToJson(c)),
        });
      }
    });
  }

  Future<void> deleteComment(String commentId) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [commentId]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Map<String, dynamic> _commentToJson(CommentModel c) => {
        'id': c.id,
        'boardOwnerId': c.boardOwnerId,
        'authorId': c.authorId,
        'authorAvatarUrl': c.authorAvatarUrl,
        'text': c.text,
        'createdAt': c.createdAt.toIso8601String(),
        'reactions': c.reactions,
        'reactedBy': c.reactedBy.map((k, v) => MapEntry(k, v)),
        'isRead': c.isRead,
        'replyCount': c.replyCount,
      };
}
