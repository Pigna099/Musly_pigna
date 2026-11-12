import 'package:flutter/material.dart';

import 'package:musly/theme/ytm_tokens.dart';
import 'package:musly/widgets/common/album_artwork.dart';

/// Album / playlist / mix / artist card used across the new UI.
///
/// Square with an 8 pt radius, two-line title, one-line subtitle. Artists use
/// [round] to get a circle.
class YtmMediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverArt;
  final Widget? artwork;
  final double size;
  final bool round;
  final VoidCallback? onTap;

  const YtmMediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverArt,
    this.artwork,
    this.size = YtmSizes.albumCard,
    this.round = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;
    final radius = round ? size / 2 : YtmRadii.card;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: artwork ??
                  AlbumArtwork(
                    coverArt: coverArt,
                    size: size,
                    borderRadius: radius,
                  ),
            ),
            const SizedBox(height: YtmSpacing.xs),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: YtmText.cardTitle.copyWith(color: fg),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YtmText.cardSubtitle.copyWith(color: secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
