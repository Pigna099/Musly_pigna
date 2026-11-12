import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:musly/models/album.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/screens/detail/album_screen.dart';
import 'package:musly/screens/main/search_screen.dart';
import 'package:musly/screens/media/album_collection_screen.dart';
import 'package:musly/screens/media/downloads_screen.dart';
import 'package:musly/screens/media/genres_screen.dart';
import 'package:musly/screens/media/radio_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/theme/ytm_tokens.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/widgets/cards/album_card.dart';
import 'package:musly/widgets/common/section_header.dart';
import 'package:musly/widgets/navigation/ytm_top_bar.dart';

/// Explore tab: category grid + new releases.
///
/// v1 of the YouTube-Music-style navigation. Charts and podcasts have no
/// self-hosted equivalent yet, so they are replaced by Radio and Downloads.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final library = Provider.of<LibraryProvider>(context);
    final username = Provider.of<AuthProvider>(context, listen: false)
            .config
            ?.username ??
        'M';

    final albums = library.newestAlbums.isNotEmpty
        ? library.newestAlbums
        : library.recentAlbums;

    return Scaffold(
      backgroundColor: isDark ? YtmColors.bg : YtmColors.lightBg,
      appBar: YtmTopBar(
        showWordmark: true,
        showSearch: true,
        showAvatar: true,
        avatarLetter: username,
        onAvatarTap: () =>
            NavigationHelper.push(context, const SettingsScreen()),
        onSearchTap: () =>
            NavigationHelper.push(context, const SearchScreen()),
      ),
      body: RefreshIndicator(
        onRefresh: () => library.refresh(),
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: YtmSpacing.md,
                vertical: YtmSpacing.xs,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: YtmSpacing.sm,
                crossAxisSpacing: YtmSpacing.sm,
                childAspectRatio: 173 / YtmSizes.categoryCardHeight,
                children: [
                  _ExploreCategoryCard(
                    icon: Icons.new_releases_outlined,
                    label: 'New releases',
                    onTap: () => NavigationHelper.push(
                      context,
                      const AlbumCollectionScreen.newReleases(),
                    ),
                  ),
                  _ExploreCategoryCard(
                    icon: Icons.category_outlined,
                    label: 'Genres',
                    onTap: () => NavigationHelper.push(
                      context,
                      const GenresScreen(),
                    ),
                  ),
                  _ExploreCategoryCard(
                    icon: Icons.radio_outlined,
                    label: 'Radio',
                    onTap: () => NavigationHelper.push(
                      context,
                      const RadioScreen(),
                    ),
                  ),
                  _ExploreCategoryCard(
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    onTap: () => NavigationHelper.push(
                      context,
                      const DownloadsScreen(),
                    ),
                  ),
                ],
              ),
            ),
            if (albums.isNotEmpty)
              HorizontalScrollSection(
                title: 'New albums & singles',
                cardSize: 152,
                itemSpacing: YtmSpacing.sm,
                onSeeAllTap: () => NavigationHelper.push(
                  context,
                  const AlbumCollectionScreen.newReleases(),
                ),
                children: albums
                    .take(12)
                    .map(
                      (Album album) => AlbumCard(
                        album: album,
                        size: 152,
                        onTap: () => NavigationHelper.push(
                          context,
                          AlbumScreen(albumId: album.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExploreCategoryCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: YtmRadii.cardRadius,
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? YtmColors.surfaceHigh : YtmColors.lightSurfaceHigh,
          borderRadius: YtmRadii.cardRadius,
        ),
        padding: const EdgeInsets.all(YtmSpacing.md),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Icon(icon, size: 26, color: fg),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
