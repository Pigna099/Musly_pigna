import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:musly/theme/ytm_tokens.dart';

/// YouTube-Music-style filter chip: 32 pt tall, 8 pt radius, no border.
class YtmFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const YtmFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedFg = isDark ? Colors.black : Colors.white;
    final normalBg =
        isDark ? YtmColors.surfaceHigh : YtmColors.lightSurfaceHigh;
    final normalFg =
        isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: YtmDurations.fast,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: YtmSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : normalBg,
          borderRadius: YtmRadii.cardRadius,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: YtmText.chip.copyWith(
            color: selected ? selectedFg : normalFg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
