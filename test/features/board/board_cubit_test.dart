import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wtf_yandex_sirius/features/board/models/comment_model.dart';
import 'package:wtf_yandex_sirius/features/board/presentation/cubits/board_cubit.dart';
import 'package:wtf_yandex_sirius/features/board/presentation/cubits/board_state.dart';
import 'package:wtf_yandex_sirius/features/board/repositories/board_repository.dart';

import 'board_cubit_test.mocks.dart';

@GenerateMocks([BoardRepository])
void main() {
  late MockBoardRepository mockRepo;

  CommentModel makeComment({
    String id = 'c1',
    String text = 'Hello',
    bool isRead = false,
    Map<String, int>? reactions,
    Map<String, List<String>>? reactedBy,
  }) {
    return CommentModel(
      id: id,
      boardOwnerId: 'owner1',
      text: text,
      createdAt: DateTime(2025, 1, 1),
      reactions: reactions ?? CommentModel.emptyReactions,
      reactedBy: reactedBy ?? CommentModel.emptyReactedBy,
      isRead: isRead,
    );
  }

  setUp(() {
    mockRepo = MockBoardRepository();
  });

  group('BoardCubit.subscribeToBoard', () {
    blocTest<BoardCubit, BoardState>(
      'emits [Loading, Loaded] with comments from stream',
      build: () {
        final comment = makeComment();
        when(mockRepo.watchBoardComments('owner1'))
            .thenAnswer((_) => Stream.value([comment]));
        return BoardCubit(mockRepo);
      },
      act: (cubit) => cubit.subscribeToBoard('owner1'),
      expect: () => [
        const BoardLoading(),
        isA<BoardLoaded>().having((s) => s.comments.length, 'length', 1),
      ],
    );

    blocTest<BoardCubit, BoardState>(
      'unread count reflects unread comments',
      build: () {
        final comments = [
          makeComment(id: 'c1', isRead: false),
          makeComment(id: 'c2', isRead: true),
          makeComment(id: 'c3', isRead: false),
        ];
        when(mockRepo.watchBoardComments('owner1'))
            .thenAnswer((_) => Stream.value(comments));
        return BoardCubit(mockRepo);
      },
      act: (cubit) => cubit.subscribeToBoard('owner1'),
      expect: () => [
        const BoardLoading(),
        isA<BoardLoaded>().having((s) => s.unreadCount, 'unreadCount', 2),
      ],
    );

    blocTest<BoardCubit, BoardState>(
      'emits [Loading, Error] on stream error',
      build: () {
        when(mockRepo.watchBoardComments('owner1'))
            .thenAnswer((_) => Stream.error(Exception('firestore error')));
        return BoardCubit(mockRepo);
      },
      act: (cubit) => cubit.subscribeToBoard('owner1'),
      expect: () => [
        const BoardLoading(),
        isA<BoardError>(),
      ],
    );
  });

  group('BoardCubit.toggleReaction (optimistic)', () {
    blocTest<BoardCubit, BoardState>(
      'optimistically updates reaction count',
      build: () {
        final comment = makeComment(id: 'c1');
        when(mockRepo.watchBoardComments('owner1'))
            .thenAnswer((_) => Stream.value([comment]));
        when(mockRepo.toggleReaction(
          commentId: 'c1',
          reactionKey: 'fire',
          userId: 'user1',
        )).thenAnswer((_) async {});
        return BoardCubit(mockRepo);
      },
      act: (cubit) async {
        cubit.subscribeToBoard('owner1');
        await Future.delayed(Duration.zero);
        cubit.toggleReaction('c1', 'fire', 'user1');
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        const BoardLoading(),
        isA<BoardLoaded>().having(
          (s) => s.comments.first.reactions['fire'],
          'fire=0',
          0,
        ),
        isA<BoardLoaded>().having(
          (s) => s.comments.first.reactions['fire'],
          'fire=1 after toggle',
          1,
        ),
      ],
    );
  });

  group('BoardCubit.deleteComment', () {
    blocTest<BoardCubit, BoardState>(
      'calls repo and does not emit extra states on success',
      build: () {
        when(mockRepo.watchBoardComments('owner1'))
            .thenAnswer((_) => const Stream.empty());
        when(mockRepo.deleteComment('c1')).thenAnswer((_) async {});
        return BoardCubit(mockRepo);
      },
      act: (cubit) async {
        cubit.subscribeToBoard('owner1');
        await cubit.deleteComment('c1');
      },
      expect: () => [const BoardLoading()],
      verify: (_) => verify(mockRepo.deleteComment('c1')).called(1),
    );
  });
}
