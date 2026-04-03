import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/app_colors.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({
    super.key,
    required this.navigationShell,
  });

  static const _tabs = <_TabSpec>[
    _TabSpec(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Доска'),
    _TabSpec(Icons.search_rounded, Icons.search_rounded, 'Поиск'),
    _TabSpec(Icons.star_border_rounded, Icons.star_rounded, 'Избранное'),
    _TabSpec(Icons.person_outline, Icons.person, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _MemeBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        tabs: _tabs,
        onSelect: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabSpec(this.icon, this.activeIcon, this.label);
}

class _MemeBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onSelect;

  const _MemeBottomNavigationBar({
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.ink.withValues(alpha: isLight ? 0.07 : 0.14),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(2, 5, 2, 4),
          child: Row(
            children: List.generate(tabs.length, (i) {
              return Expanded(
                child: _MemeTabButton(
                  key: ValueKey<int>(i),
                  selected: currentIndex == i,
                  spec: tabs[i],
                  onTap: () => onSelect(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MemeTabButton extends StatefulWidget {
  final bool selected;
  final _TabSpec spec;
  final VoidCallback onTap;

  const _MemeTabButton({
    super.key,
    required this.selected,
    required this.spec,
    required this.onTap,
  });

  @override
  State<_MemeTabButton> createState() => _MemeTabButtonState();
}

class _MemeTabButtonState extends State<_MemeTabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final iconData = widget.selected ? widget.spec.activeIcon : widget.spec.icon;
    final fg = widget.selected ? cs.primary : muted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.selected
                    ? cs.primary.withValues(alpha: 0.13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(iconData, size: 24, color: fg)
                  .animate(target: widget.selected ? 1 : 0)
                  .scale(
                    duration: 300.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShellBranches {
  static const int board = 0;
  static const int search = 1;
  static const int favorites = 2;
  static const int profile = 3;

  static int fromPath(String path) {
    if (path.startsWith('/search')) return search;
    if (path.startsWith('/favorites')) return favorites;
    if (path.startsWith('/profile')) return profile;
    return board;
  }
}
