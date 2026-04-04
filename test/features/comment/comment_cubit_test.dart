import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wtf_yandex_sirius/features/comment/presentation/cubits/comment_cubit.dart';
import 'package:wtf_yandex_sirius/features/comment/presentation/cubits/comment_state.dart';
import 'package:wtf_yandex_sirius/features/comment/repositories/comment_repository.dart';

import 'comment_cubit_test.mocks.dart';

@GenerateMocks([CommentRepository])
void main() {
  late MockCommentRepository mockRepo;

  setUp(() {
    mockRepo = MockCommentRepository();
  });

  group('CommentCubit.sendComment', () {
    blocTest<CommentCubit, CommentState>(
      'emits [Sending, Success] on success',
      build: () {
        when(mockRepo.sendComment(
          boardOwnerId: 'uid1',
          text: 'Hello!',
        )).thenAnswer((_) async {});
        return CommentCubit(mockRepo);
      },
      act: (cubit) => cubit.sendComment(boardOwnerId: 'uid1', text: 'Hello!'),
      expect: () => [
        const CommentSending(),
        const CommentSuccess(),
      ],
    );

    blocTest<CommentCubit, CommentState>(
      'emits [Sending, Error] on failure',
      build: () {
        when(mockRepo.sendComment(
          boardOwnerId: 'uid1',
          text: 'Hello!',
        )).thenThrow(Exception('permission denied'));
        return CommentCubit(mockRepo);
      },
      act: (cubit) => cubit.sendComment(boardOwnerId: 'uid1', text: 'Hello!'),
      expect: () => [
        const CommentSending(),
        isA<CommentError>(),
      ],
    );
  });

  group('CommentCubit.reset', () {
    blocTest<CommentCubit, CommentState>(
      'resets to Initial after success',
      build: () {
        when(mockRepo.sendComment(boardOwnerId: 'uid1', text: 'Hi'))
            .thenAnswer((_) async {});
        return CommentCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.sendComment(boardOwnerId: 'uid1', text: 'Hi');
        cubit.reset();
      },
      expect: () => [
        const CommentSending(),
        const CommentSuccess(),
        const CommentInitial(),
      ],
    );
  });
}
