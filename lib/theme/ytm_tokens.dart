import 'package:flutter/material.dart';

/// Design tokens for the YouTube-Music-inspired Pignify UI.
///
/// New screens must use these tokens instead of hard-coded values. The old
/// `AppTheme` constants stay in place until every screen has been migrated.
class YtmColors {
  YtmColors._();

  // Dark (default)
  static const Color bg = Color(0xFF030303);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceHigh = Color(0xFF212121);
  static const Color surfaceHighest = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF717171);
  static const Color divider = Color(0x14FFFFFF);

  // Light
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F2F2);
  static const Color lightSurfaceHigh = Color(0xFFE8E8E8);
  static const Color lightTextPrimary = Color(0xFF0F0F0F);
  static const Color lightTextSecondary = Color(0xFF606060);
  static const Color lightTextTertiary = Color(0xFF909090);
  static const Color lightDivider = Color(0x14000000);

  // Brand
  static const Color brand = Color(0xFFFF3B4E);
  static const Color danger = Color(0xFFFF5252);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

class YtmSpacing {
  YtmSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets section = EdgeInsets.fromLTRB(md, 0, md, sm);
}

class YtmRadii {
  YtmRadii._();

  static const double row = 4;
  static const double card = 8;
  static const double sheet = 12;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}

class YtmSizes {
  YtmSizes._();

  static const double topBar = 56;
  static const double bottomNav = 56;
  static const double miniPlayer = 64;
  static const double miniPlayerProgress = 2;
  static const double libraryRow = 64;
  static const double queueRow = 64;

  static const double albumCard = 152;
  static const double mixCard = 160;
  static const double artistCircle = 120;
  static const double categoryCardHeight = 108;

  static const double actionChip = 36;
  static const double playButton = 64;
  static const double searchField = 48;
  static const double nowPlayingArtworkMax = 358;

  /// Width of a horizontal card on a 390 pt screen.
  /// Two cards plus a peek always fit: `(width - 2*16 - 12) / 2.2`.
  static double horizontalCardWidth(double screenWidth) =>
      (screenWidth - 32 - 12) / 2.2;
}

class YtmText {
  YtmText._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: YtmColors.textPrimary,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: YtmColors.textPrimary,
  );
  static const TextStyle nowPlayingTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: YtmColors.textPrimary,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: YtmColors.textPrimary,
  );
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: YtmColors.textSecondary,
  );
  static const TextStyle listTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: YtmColors.textPrimary,
  );
  static const TextStyle listSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: YtmColors.textSecondary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: YtmColors.textPrimary,
  );
  static const TextStyle chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: YtmColors.textPrimary,
  );
  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: YtmColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: YtmColors.textSecondary,
  );
  static const TextStyle tab = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: YtmColors.textPrimary,
  );
}

class YtmDurations {
  YtmDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration expand = Duration(milliseconds: 300);
}
