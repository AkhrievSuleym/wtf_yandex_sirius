import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF3D2E52);
  static const Color primary = Color(0xFFE94A9B);
  static const Color primaryDark = Color(0xFFFF7AB8);
  static const Color secondary = Color(0xFF45D1E0);
  static const Color memeLime = Color(0xFFBEE867);
  static const Color memeYellow = Color(0xFFFFE566);
  static const Color memePeach = Color(0xFFFFB8A8);
  static const Color memeOrange = Color(0xFFFF8A4C);
  static const Color memeViolet = Color(0xFFA78BFA);

  static const Color backgroundLight = Color(0xFFF5F1FA);
  static const Color backgroundDark = Color(0xFF1C1426);
  static const Color surfaceLight = Color(0xFFFFFCFE);
  static const Color surfaceDark = Color(0xFF2A2235);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF352A45);

  static const Color textPrimaryLight = Color(0xFF3D2E52);
  static const Color textPrimaryDark = Color(0xFFF8F3FF);
  static const Color textSecondaryLight = Color(0xFF7D6B8A);
  static const Color textSecondaryDark = Color(0xFFC9B8D9);

  static const Color reactionFire = Color(0xFFFF6B35);
  static const Color reactionHeart = Color(0xFFFF4D8D);
  static const Color reactionLaugh = Color(0xFFFFE566);

  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFB020);

  static const Color divider = Color(0xFFE8DDF5);
  static const Color unreadBadge = Color(0xFFFF8A4C);
  static const Color shimmerBase = Color(0xFFF0E8F8);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);

  static const Color memeGradientStart = Color(0xFFFFF4C2);
  static const Color memeGradientMid = Color(0xFFFFD6EF);
  static const Color memeGradientEnd = Color(0xFFC8F4FF);

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
