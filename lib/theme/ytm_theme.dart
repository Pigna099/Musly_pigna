import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ytm_tokens.dart';

/// Material theme built from the MyMusic design tokens.
///
/// The accent is kept as `colorScheme.primary` so existing screens keep their
/// current accent colour until they are migrated one by one. New components
/// should use [YtmColors] directly.
class YtmTheme {
  YtmTheme._();

  static ThemeData dark({Color accent = YtmColors.brand}) =>
      _build(Brightness.dark, accent);

  static ThemeData light({Color accent = YtmColors.brand}) =>
      _build(Brightness.light, accent);

  static ThemeData _build(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? YtmColors.bg : YtmColors.lightBg;
    final surface = isDark ? YtmColors.surface : YtmColors.lightSurface;
    final card = isDark ? YtmColors.surfaceHigh : YtmColors.lightSurfaceHigh;
    final text = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final textSecondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;
    final divider = isDark ? YtmColors.divider : YtmColors.lightDivider;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      error: YtmColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: YtmRadii.cardRadius),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: text),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: text,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: YtmSpacing.md),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? YtmColors.surface : YtmColors.lightBg,
        selectedItemColor: text,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: YtmText.navLabel.copyWith(color: text),
        unselectedLabelStyle: YtmText.navLabel.copyWith(color: textSecondary),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? YtmColors.surface : YtmColors.lightBg,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          YtmText.navLabel.copyWith(color: text),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: text,
        disabledColor: card,
        labelStyle: YtmText.chip.copyWith(color: text),
        secondaryLabelStyle: YtmText.chip.copyWith(color: bg),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: YtmRadii.cardRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: YtmSpacing.sm,
          vertical: YtmSpacing.xs,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: text,
        inactiveTrackColor: text.withValues(alpha: 0.24),
        thumbColor: text,
        overlayColor: text.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: text,
        linearTrackColor: text.withValues(alpha: 0.24),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? YtmColors.surfaceHighest : YtmColors.black,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YtmRadii.card)),
        ),
      ),
      textTheme: _textTheme(isDark),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: accent,
        barBackgroundColor: bg,
        scaffoldBackgroundColor: bg,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: text, fontSize: 15),
          navTitleTextStyle: TextStyle(
            color: text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final text = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: text,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: text,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: text,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: text,
      ),
      bodyLarge: TextStyle(fontSize: 17, color: text),
      bodyMedium: TextStyle(fontSize: 15, color: text),
      bodySmall: TextStyle(fontSize: 13, color: secondary),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
    );
  }
}
