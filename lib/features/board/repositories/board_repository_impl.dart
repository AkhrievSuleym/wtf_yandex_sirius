import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/comment_cache_db.dart';
import '../../../core/utils/app_logger.dart';
import '../models/comment_model.dart';
import 'board_repository.dart';

class BoardRepositoryImpl implements BoardRepository {
  static const _tag = 'BoardRepository';

  final ApiClient _api;
  final CommentCacheDb _cacheDb;

  BoardRepositoryImpl(this._api, this._cacheDb);

  @override
  Stream<List<CommentModel>> watchBoardComments(String ownerId) {
    AppLogger.d(_tag, 'watchBoardComments: ownerId=$ownerId');

    final controller = StreamController<List<CommentModel>>();
    HttpClient? client;
    StreamSubscription<String>? sseSub;
    Timer? sseReconnect;

    Future<void> fetchAndEmit() async {
      try {
        final response = await _api.dio.get('/comments/board/$ownerId');
        final list = (response.data as List)
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        await _cacheDb.saveComments(ownerId, list);
        AppLogger.d(_tag, 'watchBoardComments: ${list.length} comments');
        if (!controller.isClosed) controller.add(list);
      } on DioException catch (e) {
        AppLogger.e(_tag, 'fetch failed — no network, keeping cache', e);
      }
    }

    Future<void> connectSSE() async {
      void scheduleReconnect() {
        sseReconnect?.cancel();
        sseReconnect = Timer(const Duration(seconds: 2), () {
          if (!controller.isClosed) connectSSE();
        });
      }

      try {
        await sseSub?.cancel();
        client?.close(force: true);
        client = HttpClient();
        final token = _api.token ?? '';
        final uri =
            Uri.parse('${ApiConstants.baseUrl}/comments/board/$ownerId/stream');
        final req = await client!.getUrl(uri);
        req.headers.set('Authorization', 'Bearer $token');
        req.headers.set('Accept', 'text/event-stream');
        final resp = await req.close();
        sseSub = resp
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.startsWith('data:')) {
              AppLogger.d(_tag, 'SSE update');
              fetchAndEmit();
            }
          },
          onError: (e) {
            AppLogger.w(_tag, 'SSE error: $e');
            scheduleReconnect();
          },
          onDone: () {
            AppLogger.d(_tag, 'SSE stream ended');
            scheduleReconnect();
          },
          cancelOnError: false,
        );
      } catch (e) {
        AppLogger.w(_tag, 'SSE connect failed: $e');
        scheduleReconnect();
      }
    }

    Future<void> startWithCache() async {
      final cached = await _cacheDb.loadComments(ownerId);
      if (cached.isNotEmpty && !controller.isClosed) {
        AppLogger.d(_tag, 'watchBoardComments: serving ${cached.length} from db cache');
        controller.add(cached);
      }
      fetchAndEmit();
      connectSSE();
    }

    startWithCache();

    controller.onCancel = () {
      sseReconnect?.cancel();
      sseSub?.cancel();
      client?.close(force: true);
    };

    return controller.stream;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    AppLogger.i(_tag, 'deleteComment: id=$commentId');
    await _api.dio.delete('/comments/$commentId');
    await _cacheDb.deleteComment(commentId);
  }

  @override
  Future<void> markAsRead(String commentId) async {
    AppLogger.d(_tag, 'markAsRead: id=$commentId');
    await _api.dio.put('/comments/$commentId/read');
  }

  @override
  Future<void> toggleReaction({
    required String commentId,
    required String reactionKey,
    required String userId,
  }) async {
    AppLogger.d(_tag, 'toggleReaction: commentId=$commentId key=$reactionKey');
    await _api.dio.post('/comments/$commentId/reaction', data: {
      'reactionKey': reactionKey,
      'userId': userId,
    });
  }
}
