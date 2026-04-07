import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF1A0E2E);
  static const Color primary = Color(0xFF6B3FA0);
  static const Color primaryDark = Color(0xFF9B6FD0);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color memeLime = Color(0xFF7C3AED);
  static const Color memeYellow = Color(0xFFDDD6FE);
  static const Color memePeach = Color(0xFFEDE9FE);
  static const Color memeOrange = Color(0xFF7C3AED);
  static const Color memeViolet = Color(0xFF8B5CF6);

  static const Color backgroundLight = Color(0xFFF3F0FA);
  static const Color backgroundDark = Color(0xFF0D0818);
  static const Color surfaceLight = Color(0xFFFAF8FF);
  static const Color surfaceDark = Color(0xFF1A1228);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF251A3A);

  static const Color textPrimaryLight = Color(0xFF1A0E2E);
  static const Color textPrimaryDark = Color(0xFFF0EAFF);
  static const Color textSecondaryLight = Color(0xFF6B5B80);
  static const Color textSecondaryDark = Color(0xFFB8A8D4);

  static const Color reactionFire = Color(0xFFFF6B35);
  static const Color reactionHeart = Color(0xFFFF4D8D);
  static const Color reactionLaugh = Color(0xFFFFE566);

  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFB020);

  static const Color divider = Color(0xFF2E1F4A);
  static const Color unreadBadge = Color(0xFF7C3AED);
  static const Color shimmerBase = Color(0xFF2A1F3D);
  static const Color shimmerHighlight = Color(0xFF3D2E5A);

  static const Color memeGradientStart = Color(0xFF1A0E2E);
  static const Color memeGradientMid = Color(0xFF2D1B4E);
  static const Color memeGradientEnd = Color(0xFF1E1535);

  static Color reactionTintForKey(String key) {
    return switch (key) {
      'fire' => reactionFire,
      'heart' => reactionHeart,
      'laugh' => reactionLaugh,
      'poop' => const Color(0xFF8B6914),
      'clown' => memeViolet,
      _ => primary,
    };
  }
}
