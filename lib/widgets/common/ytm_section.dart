import 'package:flutter/material.dart';

import 'package:musly/theme/ytm_tokens.dart';

/// Section with a 22 pt title and a horizontal list of cards.
///
/// Mirrors YouTube Music's `Title` + carousel pattern. `cardHeight` must leave
/// room for the artwork plus two lines of text.
class YtmSection extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  final List<Widget> children;
  final double cardHeight;
  final EdgeInsets padding;

  const YtmSection({
    super.key,
    required this.title,
    this.onMore,
    required this.children,
    this.cardHeight = 216,
    this.padding = const EdgeInsets.symmetric(horizontal: YtmSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YtmText.sectionTitle.copyWith(color: fg),
                ),
              ),
              if (onMore != null) _MorePill(onTap: onMore!),
            ],
          ),
        ),
        const SizedBox(height: YtmSpacing.sm),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: YtmSpacing.sm),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class _MorePill extends StatelessWidget {
  final VoidCallback onTap;

  const _MorePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: YtmRadii.pillRadius,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: YtmSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: fg.withValues(alpha: 0.24)),
          borderRadius: YtmRadii.pillRadius,
        ),
        child: Text(
          'More',
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
