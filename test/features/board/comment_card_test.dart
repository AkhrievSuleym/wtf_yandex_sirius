import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_yandex_sirius/features/board/models/comment_model.dart';
import 'package:wtf_yandex_sirius/features/board/presentation/widgets/comment_card.dart';
import 'package:wtf_yandex_sirius/app/theme/app_theme.dart';

void main() {
  final testComment = CommentModel(
    id: '1',
    boardOwnerId: 'owner_123',
    authorId: 'user_123',
    text: 'Test comment content',
    createdAt: DateTime.now(),
    reactions: CommentModel.emptyReactions,
    reactedBy: CommentModel.emptyReactedBy,
    isRead: true,
  );

  testWidgets('CommentCard displays text and "Ты" label for current user',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CommentCard(
            comment: testComment,
            currentUserId: 'user_123', // Matches authorId
            isBoardOwnerView: false,
            onToggleReaction: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Test comment content'), findsOneWidget);
    expect(find.text('Ты'), findsOneWidget);
  });

  testWidgets('CommentCard displays "Анонимно" for null authorId',
      (WidgetTester tester) async {
    final anonComment = CommentModel(
      id: '2',
      boardOwnerId: 'owner_123',
      authorId: null,
      text: 'Anonymous test comment',
      createdAt: DateTime.now(),
      reactions: CommentModel.emptyReactions,
      reactedBy: CommentModel.emptyReactedBy,
      isRead: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CommentCard(
            comment: anonComment,
            currentUserId: 'any_id',
            isBoardOwnerView: false,
            onToggleReaction: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Анонимно'), findsOneWidget);
  });

  testWidgets('CommentCard displays "Владелец доски" for board owner',
      (WidgetTester tester) async {
    final ownerComment = CommentModel(
      id: '3',
      boardOwnerId: 'owner_123',
      authorId: 'owner_123',
      text: 'Owner test comment',
      createdAt: DateTime.now(),
      reactions: CommentModel.emptyReactions,
      reactedBy: CommentModel.emptyReactedBy,
      isRead: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CommentCard(
            comment: ownerComment,
            currentUserId: 'other_user',
            isBoardOwnerView: false,
            onToggleReaction: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Владелец доски'), findsOneWidget);
  });
}
