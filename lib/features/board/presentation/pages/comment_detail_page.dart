import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../cubits/board_cubit.dart';
import '../../models/reply_model.dart';

class CommentDetailPage extends StatefulWidget {
  final String commentId;
  final String commentText;
  final DateTime commentCreatedAt;
  final String boardOwnerUid;
  final bool isOwner;
  final String? commentAuthorId;
  final String? commentAuthorAvatarUrl;

  const CommentDetailPage({
    super.key,
    required this.commentId,
    required this.commentText,
    required this.commentCreatedAt,
    required this.boardOwnerUid,
    required this.isOwner,
    this.commentAuthorId,
    this.commentAuthorAvatarUrl,
  });

  @override
  State<CommentDetailPage> createState() => _CommentDetailPageState();
}

class _CommentDetailPageState extends State<CommentDetailPage> {
  static const _tag = 'CommentDetailPage';

  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _api = getIt<ApiClient>();

  List<ReplyModel> _replies = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReplies();
    // Mark comment as read if owner
    if (widget.isOwner) {
      context.read<BoardCubit>().markAsRead(widget.commentId);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await _api.dio.get('/comments/${widget.commentId}/replies');
      final list = (response.data as List)
          .map((e) => ReplyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _replies = list);
    } catch (e) {
      AppLogger.e(_tag, 'loadReplies failed', e);
      if (mounted) setState(() => _error = 'Не удалось загрузить ответы');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final response = await _api.dio.post(
        '/comments/${widget.commentId}/replies',
        data: {'text': text},
      );
      final reply = ReplyModel.fromJson(response.data as Map<String, dynamic>);
      _replyController.clear();
      if (mounted) {
        setState(() => _replies = [..._replies, reply]);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      AppLogger.e(_tag, 'sendReply failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить ответ')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteReply(String replyId) async {
    try {
      await _api.dio.delete('/replies/$replyId');
      if (mounted) {
        setState(
            () => _replies = _replies.where((r) => r.id != replyId).toList());
      }
    } catch (e) {
      AppLogger.e(_tag, 'deleteReply failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить ответ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Сообщение')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Original comment bubble
                _CommentBubble(
                  text: widget.commentText,
                  createdAt: widget.commentCreatedAt,
                  boardOwnerUid: widget.boardOwnerUid,
                  authorId: widget.commentAuthorId,
                  authorAvatarUrl: widget.commentAuthorAvatarUrl,
                  currentUserId: currentUserId,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(_error!, style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: _loadReplies,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                else if (_replies.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Ответов пока нет — напишите ниже',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  )
                else
                  ...(_replies.map((reply) => _ReplyBubble(
                        reply: reply,
                        boardOwnerUid: widget.boardOwnerUid,
                        currentUserId: currentUserId,
                        canDelete: currentUserId.isNotEmpty &&
                            reply.ownerUid != null &&
                            reply.ownerUid == currentUserId,
                        onDelete: () => _deleteReply(reply.id),
                        theme: theme,
                      ))),
              ],
            ),
          ),
          _ReplyInput(
            controller: _replyController,
            sending: _sending,
            onSend: _sendReply,
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final String text;
  final DateTime createdAt;
  final String boardOwnerUid;
  final String? authorId;
  final String? authorAvatarUrl;
  final String currentUserId;
  final ThemeData theme;

  const _CommentBubble({
    required this.text,
    required this.createdAt,
    required this.boardOwnerUid,
    required this.authorId,
    required this.authorAvatarUrl,
    required this.currentUserId,
    required this.theme,
  });

  String get _label {
    if (authorId == null) return 'Анонимно';
    if (authorId == currentUserId) return 'Ты';
    if (authorId == boardOwnerUid) return 'Владелец доски';
    return 'Участник';
  }

  Color get _chipBg {
    if (authorId == null) return AppColors.memeYellow.withValues(alpha: 0.92);
    if (authorId == currentUserId) {
      return AppColors.primaryDark.withValues(alpha: 0.22);
    }
    if (authorId == boardOwnerUid) {
      return AppColors.memeViolet.withValues(alpha: 0.35);
    }
    return AppColors.primary.withValues(alpha: 0.14);
  }

  Color get _border {
    if (authorId == null) return AppColors.ink.withValues(alpha: 0.12);
    if (authorId == currentUserId) {
      return AppColors.primaryDark.withValues(alpha: 0.15);
    }
    if (authorId == boardOwnerUid) {
      return AppColors.memeViolet.withValues(alpha: 0.55);
    }
    return AppColors.primary.withValues(alpha: 0.35);
  }

  double get _borderW => authorId == null ? 1.5 : 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
          width: _borderW,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.memeViolet.withValues(alpha: 0.22),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                avatarUrl: authorAvatarUrl,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _chipBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.ink.withValues(alpha: 0.2),
                          width: 1.25,
                        ),
                      ),
                      child: Text(
                        _label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textPrimaryDark
                              : AppColors.ink,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.relative(createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final ReplyModel reply;
  final String boardOwnerUid;
  final String currentUserId;
  final bool canDelete;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _ReplyBubble({
    required this.reply,
    required this.boardOwnerUid,
    required this.currentUserId,
    required this.canDelete,
    required this.onDelete,
    required this.theme,
  });

  String get _authorLabel {
    if (reply.ownerUid == null) return 'Анонимно';
    if (reply.ownerUid == boardOwnerUid) return 'Владелец доски';
    if (currentUserId.isNotEmpty && reply.ownerUid == currentUserId) {
      return 'Вы';
    }
    return 'Участник';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          ProfileAvatar(
            avatarUrl: reply.ownerAvatarUrl,
            size: 36,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Icon(
              Icons.subdirectory_arrow_right,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.memeViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.45), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _authorLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textPrimaryDark
                              : AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormatter.relative(reply.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (canDelete) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _confirmDelete(context),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(reply.text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить ответ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Ответить...',
                  counterText: '',
                  fillColor: Theme.of(context).colorScheme.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.ink, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColors.ink.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink, width: 2.5),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
