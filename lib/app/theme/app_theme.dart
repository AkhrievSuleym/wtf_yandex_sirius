import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffoldBg: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        cardColor: AppColors.cardLight,
        onSurface: AppColors.textPrimaryLight,
        bodySmallColor: AppColors.textSecondaryLight,
        appBarBg: AppColors.backgroundLight,
        appBarFg: AppColors.ink,
        inputFill: AppColors.surfaceLight,
        dividerBorder: AppColors.ink,
        navBg: AppColors.surfaceLight,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffoldBg: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        cardColor: AppColors.cardDark,
        onSurface: AppColors.textPrimaryDark,
        bodySmallColor: AppColors.textSecondaryDark,
        appBarBg: AppColors.backgroundDark,
        appBarFg: AppColors.textPrimaryDark,
        inputFill: AppColors.surfaceDark,
        dividerBorder: AppColors.secondary,
        navBg: AppColors.surfaceDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color cardColor,
    required Color onSurface,
    required Color bodySmallColor,
    required Color appBarBg,
    required Color appBarFg,
    required Color inputFill,
    required Color dividerBorder,
    required Color navBg,
  }) {
    final isLight = brightness == Brightness.light;
    final primary = isLight ? AppColors.primary : AppColors.primaryDark;
    const secondary = AppColors.secondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: AppColors.ink,
      tertiary: AppColors.memeViolet,
      onTertiary: AppColors.ink,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.error,
      onError: Colors.white,
      surfaceContainerHighest: isLight
          ? AppColors.memeViolet.withValues(alpha: 0.12)
          : AppColors.memeViolet.withValues(alpha: 0.22),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final textTheme = GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final borderRadius = BorderRadius.circular(18);
    final stickerSide = BorderSide(
      color: isLight
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.primaryDark.withValues(alpha: 0.30),
      width: 1.5,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: stickerSide,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          color: appBarFg,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: stickerSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: dividerBorder.withValues(alpha: isLight ? 0.35 : 0.5),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: isLight ? AppColors.primary : AppColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? AppColors.primary : AppColors.primaryDark,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(
            color: isLight
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primaryDark.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: GoogleFonts.fredoka(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight ? AppColors.primary : AppColors.primaryDark,
          textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: primary,
        unselectedItemColor: isLight
            ? AppColors.textSecondaryLight
            : AppColors.textSecondaryDark,
        selectedLabelStyle: GoogleFonts.fredoka(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.fredoka(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:
            isLight ? AppColors.primary : AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.15,
        ),
        headlineSmall: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(color: bodySmallColor),
      ),
    );
  }
}
