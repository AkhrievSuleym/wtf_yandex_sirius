import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/di/injection.dart';
import '../app/theme/app_colors.dart';
import '../core/services/connectivity_service.dart';
import '../features/auth/presentation/cubits/auth_cubit.dart';
import '../features/auth/presentation/cubits/auth_state.dart';
import '../features/profile/presentation/cubits/profile_cubit.dart';

class ScaffoldWithBottomNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({
    super.key,
    required this.navigationShell,
  });

  @override
  State<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends State<ScaffoldWithBottomNav> {
  static const _tabs = <_TabSpec>[
    _TabSpec(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Доска'),
    _TabSpec(Icons.search_rounded, Icons.search_rounded, 'Поиск'),
    _TabSpec(Icons.star_border_rounded, Icons.star_rounded, 'Избранное'),
    _TabSpec(Icons.person_outline, Icons.person, 'Профиль'),
  ];

  late final ConnectivityService _connectivity;
  late final StreamSubscription<bool> _sub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivity = getIt<ConnectivityService>();
    _isOnline = _connectivity.isOnline;
    _sub = _connectivity.onStatusChange.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _OfflineBanner(isOnline: _isOnline),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: _MemeBottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        tabs: _tabs,
        onSelect: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
          if (index == ShellBranches.profile) {
            final auth = context.read<AuthCubit>().state;
            if (auth is AuthAuthenticated) {
              context.read<ProfileCubit>().loadProfile(auth.user.uid);
            }
          }
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isOnline;

  const _OfflineBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return GestureDetector(
      onTap: () => getIt<ConnectivityService>().forceCheck(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        clipBehavior: Clip.hardEdge,
        height: isOnline ? 0.0 : topPadding + 32.0,
        width: double.infinity,
        color: const Color(0xFF2C2C2E),
        child: isOnline
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 8.0,
                    bottom: 8.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Нет подключения — показываем кеш',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
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
        : AppColors.textSecondaryDark;
    final iconData =
        widget.selected ? widget.spec.activeIcon : widget.spec.icon;
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
