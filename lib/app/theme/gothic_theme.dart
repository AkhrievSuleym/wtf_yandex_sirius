import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ███ GOTHIC / HAUNTED DUNGEON THEME ███
///
/// Fonts (все поддерживают кириллицу):
///   • StalinistOne — display. Тяжёлый, монументальный, мрачный.
///                    Изначально создан для русских букв.
///   • Spectral SemiBold — titles / AppBar. Тёмный editorial serif.
///   • Spectral Regular — body. Читаемый при любом размере.
///
/// Палитра (dungeon всегда тёмный — оба режима):
///   #0D0D12  — бездна (bg dark)
///   #1A1A22  — каменная сталь (bg light / dungeon torch)
///   #2A2038  — тёмная карта
///   #C0182A  — запёкшаяся кровь (primary light)
///   #E03040  — свежая кровь (primary dark)
///   #9E7C3A  — потускневшее золото (border accent)
///   #EDE0D4  — кость (text)
class GothicTheme {
  GothicTheme._();

  // ─── Palette ────────────────────────────────────────────────────────────────
  static const Color _primary      = Color(0xFFC0182A); // dried blood
  static const Color _primaryDark  = Color(0xFFE03040); // fresh blood

  static const Color _bgLight      = Color(0xFF1A1A22); // dungeon stone
  static const Color _bgDark       = Color(0xFF0D0D12); // abyss
  static const Color _surfaceLight = Color(0xFF22222E);
  static const Color _surfaceDark  = Color(0xFF14141C);
  static const Color _cardLight    = Color(0xFF2A2038);
  static const Color _cardDark     = Color(0xFF1C1428);

  static const Color _textLight    = Color(0xFFEDE0D4); // bone white
  static const Color _textDark     = Color(0xFFF0E0D0);
  static const Color _textSecLight = Color(0xFF8A7A6E); // ash
  static const Color _textSecDark  = Color(0xFF7A6A5E);

  static const Color _gold         = Color(0xFF9E7C3A); // tarnished gold
  static const Color _goldBright   = Color(0xFFB8973E);

  static const Color _error        = Color(0xFFCC2020);
  static const Color _success      = Color(0xFF2E7D32);

  // ─── Public accessors ───────────────────────────────────────────────────────
  static Color get primary     => _primary;
  static Color get primaryDark => _primaryDark;
  static Color get gold        => _gold;
  static Color get error       => _error;
  static Color get success     => _success;

  // ─── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get light => _build(
    brightness: Brightness.light,
    primary:    _primary,
    scaffoldBg: _bgLight,
    surface:    _surfaceLight,
    cardColor:  _cardLight,
    onSurface:  _textLight,
    textSec:    _textSecLight,
    appBarBg:   _bgLight,
    inputFill:  _surfaceLight,
    navBg:      _bgLight,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    primary:    _primaryDark,
    scaffoldBg: _bgDark,
    surface:    _surfaceDark,
    cardColor:  _cardDark,
    onSurface:  _textDark,
    textSec:    _textSecDark,
    appBarBg:   _bgDark,
    inputFill:  _surfaceDark,
    navBg:      _bgDark,
  );

  // ─── Builder ────────────────────────────────────────────────────────────────
  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color scaffoldBg,
    required Color surface,
    required Color cardColor,
    required Color onSurface,
    required Color textSec,
    required Color appBarBg,
    required Color inputFill,
    required Color navBg,
  }) {
    final goldBorder    = BorderSide(color: _gold.withValues(alpha: 0.45), width: 1);
    final crimsonBorder = BorderSide(color: primary.withValues(alpha: 0.8), width: 1);
    final sharpRadius   = BorderRadius.circular(2);
    final cardRadius    = BorderRadius.circular(4);

    final colorScheme = ColorScheme(
      brightness:              brightness,
      primary:                 primary,
      onPrimary:               const Color(0xFFEDE0D4),
      secondary:               _gold,
      onSecondary:             const Color(0xFF0D0D12),
      tertiary:                _goldBright,
      onTertiary:              const Color(0xFF0D0D12),
      error:                   _error,
      onError:                 _textLight,
      surface:                 surface,
      onSurface:               onSurface,
      surfaceContainerHighest: cardColor.withValues(alpha: 0.9),
      outline:                 _gold.withValues(alpha: 0.4),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness:   brightness,
      colorScheme:  colorScheme,
    );

    // ── Вспомогательные построители стилей ──────────────────────────────────

    // StalinistOne — кириллица, тяжёлый монументальный блок
    TextStyle stalinist(double size, {double spacing = 0.5, Color? color}) =>
        GoogleFonts.stalinistOne(
          fontSize:      size,
          letterSpacing: spacing,
          color:         color ?? onSurface,
          height:        1.1,
        );

    // Spectral — кириллица, элегантный тёмный serif
    TextStyle spectral(
      double size, {
      FontWeight w = FontWeight.w400,
      bool italic = false,
      double spacing = 0.1,
      Color? color,
    }) =>
        GoogleFonts.spectral(
          fontSize:      size,
          fontWeight:    w,
          fontStyle:     italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: spacing,
          color:         color ?? onSurface,
          height:        1.45,
        );

    // ── TextTheme ────────────────────────────────────────────────────────────
    final textTheme = base.textTheme.copyWith(
      // Большие заголовки — StalinistOne, максимальная мрачность
      displayLarge:  stalinist(40, spacing: 1.5),
      displayMedium: stalinist(32, spacing: 1.2),
      displaySmall:  stalinist(26, spacing: 1.0),
      headlineLarge:  stalinist(24, spacing: 0.8),
      headlineMedium: stalinist(20, spacing: 0.6),
      // AppBar, карточки — Spectral Bold
      headlineSmall: spectral(18, w: FontWeight.w700, spacing: 0.3),
      titleLarge:    spectral(16, w: FontWeight.w700, spacing: 0.2),
      titleMedium:   spectral(15, w: FontWeight.w600, spacing: 0.1),
      titleSmall:    spectral(13, w: FontWeight.w600, spacing: 0.1),
      // Body — Spectral Regular/Italic
      bodyLarge:  spectral(15),
      bodyMedium: spectral(14),
      bodySmall:  spectral(12, color: textSec),
      // Labels — Spectral SemiBold компактный
      labelLarge:  spectral(13, w: FontWeight.w600, spacing: 0.4),
      labelMedium: spectral(11, w: FontWeight.w500, spacing: 0.3),
      labelSmall:  spectral(10, w: FontWeight.w400, color: textSec),
    );

    // ── Components ───────────────────────────────────────────────────────────
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,

      cardTheme: CardThemeData(
        color:       cardColor,
        elevation:   0,
        shadowColor: primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side:         goldBorder,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:  appBarBg,
        foregroundColor:  onSurface,
        elevation:        0,
        centerTitle:      true,
        shadowColor:      Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // AppBar заголовок — StalinistOne
        titleTextStyle: stalinist(17, spacing: 1.5, color: onSurface),
        iconTheme:      IconThemeData(color: onSurface),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: sharpRadius,
          borderSide:   goldBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: sharpRadius,
          borderSide: BorderSide(
            color: _gold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: sharpRadius,
          borderSide:   crimsonBorder,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: sharpRadius,
          borderSide:   const BorderSide(color: _error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: sharpRadius,
          borderSide:   const BorderSide(color: _error, width: 2),
        ),
        labelStyle: spectral(13, color: textSec, spacing: 0.3),
        hintStyle:  spectral(14, italic: true, color: textSec),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation:       0,
          backgroundColor: primary,
          foregroundColor: _textLight,
          minimumSize:     const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: sharpRadius,
            side: BorderSide(
              color: _goldBright.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          // Кнопки — StalinistOne
          textStyle: stalinist(14, spacing: 2.0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side:  crimsonBorder,
          shape: RoundedRectangleBorder(borderRadius: sharpRadius),
          textStyle: stalinist(14, spacing: 2.0),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: spectral(13, w: FontWeight.w600, spacing: 0.3),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textSec),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.35)
                : surface),
        trackOutlineColor: WidgetStateProperty.all(
            _gold.withValues(alpha: 0.4)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:     navBg,
        selectedItemColor:   primary,
        unselectedItemColor: textSec,
        selectedLabelStyle:  spectral(10, w: FontWeight.w600, spacing: 0.3),
        unselectedLabelStyle: spectral(10),
        type:      BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: _textLight,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: sharpRadius,
          side: BorderSide(
            color: _goldBright.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color:     _gold.withValues(alpha: 0.25),
        thickness: 0.5,
      ),

      listTileTheme: ListTileThemeData(
        iconColor:         textSec,
        textColor:         onSurface,
        titleTextStyle:    spectral(15),
        subtitleTextStyle: spectral(13, color: textSec),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  cardColor,
        contentTextStyle: spectral(14, color: _textLight),
        shape: RoundedRectangleBorder(
          borderRadius: sharpRadius,
          side:         goldBorder,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side:         goldBorder,
        ),
        titleTextStyle:   stalinist(17, spacing: 0.5, color: onSurface),
        contentTextStyle: spectral(14, color: onSurface),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          side:         goldBorder,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:            primary,
        linearTrackColor: surface,
      ),

      iconTheme: IconThemeData(color: onSurface),

      textTheme: textTheme,
    );
  }
}
