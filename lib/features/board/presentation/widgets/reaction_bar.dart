import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../../../app/theme/app_colors.dart';

class ReactionBar extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final Future<void> Function(String reactionKey) onToggle;

  const ReactionBar({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CommentModel.reactionKeys.map((key) {
        final count = comment.reactions[key] ?? 0;
        final isActive = comment.hasReacted(key, currentUserId);

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _ReactionChip(
            reactionKey: key,
            emoji: CommentModel.emojiFor(key),
            count: count,
            isActive: isActive,
            onTap: () async {
              await onToggle(key);
            },
          ),
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatefulWidget {
  final String reactionKey;
  final String emoji;
  final int count;
  final bool isActive;
  final Future<void> Function() onTap;

  const _ReactionChip({
    required this.reactionKey,
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popCtrl;

  static final Animatable<double> _emojiScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.38)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 32,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.38, end: 0.94)
          .chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.94, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 46,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _popCtrl.forward(from: 0);
    await widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final tint = AppColors.reactionTintForKey(widget.reactionKey);
    final scaleAnim = _emojiScale.animate(_popCtrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(),
        borderRadius: BorderRadius.circular(22),
        splashColor: tint.withValues(alpha: 0.25),
        highlightColor: tint.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? tint.withValues(alpha: 0.2)
                : surface,
            border: Border.all(
              color: widget.isActive
                  ? tint.withValues(alpha: 0.65)
                  : AppColors.ink.withValues(alpha: 0.1),
              width: widget.isActive ? 2 : 1.25,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _popCtrl,
                builder: (context, child) {
                  return Transform.scale(
                    scale: scaleAnim.value,
                    child: child,
                  );
                },
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: Text(
                    '${widget.count}',
                    key: ValueKey(widget.count),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: widget.isActive
                          ? tint
                          : Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
