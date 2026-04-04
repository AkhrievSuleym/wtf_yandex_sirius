import 'dart:math' as math;

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
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
        ),
      ),
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

  final _burstRandom = math.Random();

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

  void _playBurst(Offset globalOrigin) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ReactionBurstOverlay(
        origin: globalOrigin,
        emoji: widget.emoji,
        random: _burstRandom,
        onDone: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _handleTap() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _playBurst(box.localToGlobal(box.size.center(Offset.zero)));
    }
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
            color: widget.isActive ? tint.withValues(alpha: 0.2) : surface,
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

class _ReactionBurstOverlay extends StatefulWidget {
  final Offset origin;
  final String emoji;
  final math.Random random;
  final VoidCallback onDone;

  const _ReactionBurstOverlay({
    required this.origin,
    required this.emoji,
    required this.random,
    required this.onDone,
  });

  @override
  State<_ReactionBurstOverlay> createState() => _ReactionBurstOverlayState();
}

class _ReactionBurstOverlayState extends State<_ReactionBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_BurstParticle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onDone();
        }
      });
    _particles = List.generate(10, (i) {
      final base = (i / 10) * math.pi * 2 + widget.random.nextDouble() * 0.5;
      final dist = 38.0 + widget.random.nextDouble() * 52;
      final rot = widget.random.nextDouble() * 0.8 - 0.4;
      return _BurstParticle(
        angle: base,
        distance: dist,
        rotation: rot,
        size: 11.0 + widget.random.nextDouble() * 9,
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = Curves.easeOutQuad.transform(_ctrl.value);
            final opacity = (1.0 - _ctrl.value * 1.15).clamp(0.0, 1.0);
            return SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final p in _particles)
                    Positioned(
                      left: widget.origin.dx +
                          math.cos(p.angle) * p.distance * t -
                          p.size / 2,
                      top: widget.origin.dy +
                          math.sin(p.angle) * p.distance * t -
                          p.size / 2,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: p.rotation * t * 4,
                          child: Text(
                            widget.emoji,
                            style: TextStyle(fontSize: p.size),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BurstParticle {
  final double angle;
  final double distance;
  final double rotation;
  final double size;

  _BurstParticle({
    required this.angle,
    required this.distance,
    required this.rotation,
    required this.size,
  });
}
