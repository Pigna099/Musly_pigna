import 'package:flutter/material.dart';
import 'package:musly/theme/ytm_tokens.dart';

/// YouTube-Music-style top bar.
///
/// Home/Explore use the MyMusic wordmark; Library and detail pages use a title.
/// Search and the profile avatar live on the right, as in YT Music.
class YtmTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showWordmark;
  final List<Widget> actions;
  final VoidCallback? onSearchTap;
  final bool showSearch;
  final bool showAvatar;
  final String avatarLetter;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const YtmTopBar({
    super.key,
    this.title,
    this.showWordmark = false,
    this.actions = const [],
    this.onSearchTap,
    this.showSearch = false,
    this.showAvatar = false,
    this.avatarLetter = 'M',
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        YtmSizes.topBar + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final bg = isDark ? YtmColors.bg : YtmColors.lightBg;
    final surface =
        isDark ? YtmColors.surfaceHigh : YtmColors.lightSurfaceHigh;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? YtmSpacing.md : 0,
      toolbarHeight: YtmSizes.topBar,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: showWordmark
          ? _Wordmark(color: fg)
          : Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
      actions: [
        ...actions,
        if (showSearch)
          IconButton(
            tooltip: 'Search',
            icon: Icon(Icons.search_rounded, color: fg, size: 24),
            onPressed: onSearchTap,
          ),
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
              child: Text(
                avatarLetter.isEmpty ? 'M' : avatarLetter[0].toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (!showAvatar) const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}

class _Wordmark extends StatelessWidget {
  final Color color;

  const _Wordmark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: YtmColors.brand,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'MyMusic',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
