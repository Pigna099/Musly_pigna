import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:musly/models/models.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/screens/detail/album_screen.dart';
import 'package:musly/screens/detail/artist_screen.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/screens/media/album_collection_screen.dart';
import 'package:musly/screens/media/playlists_screen.dart';
import 'package:musly/screens/settings/settings_screen.dart';
import 'package:musly/services/offline_service.dart';
import 'package:musly/services/recommendation_service.dart';
import 'package:musly/theme/ytm_tokens.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/widgets/cards/ytm_media_card.dart';
import 'package:musly/widgets/common/playlist_artwork.dart';
import 'package:musly/widgets/common/ytm_filter_chip.dart';
import 'package:musly/widgets/common/ytm_section.dart';
import 'package:musly/widgets/navigation/ytm_top_bar.dart';
import 'search_screen.dart';

/// YouTube-Music-style Home: wordmark, filter chips, then horizontal rows
/// (Listen again, Your mixes, New releases, Discover, Recently added).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _cachedMixes = const {};
  List<Song> _cachedPersonalized = const [];
  List<Song> _cachedListenAgain = const [];
  List<Song> _cachedTopHits = const [];
  String _lastRandomKey = '';
  String _selectedCategory = 'All';

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  String _computeRandomKey(List<Song> songs, RecommendationService rec) {
    if (songs.isEmpty) return '';
    final lastPlayed =
        rec.recentlyPlayed.isNotEmpty ? rec.recentlyPlayed.first : '';
    return '${songs.length}_${songs.first.id}_${songs.last.id}_${rec.profiles.length}_${rec.recentlyPlayed.length}_$lastPlayed';
  }

  void _openAlbum(BuildContext context, String albumId) {
    NavigationHelper.push(context, AlbumScreen(albumId: albumId));
  }

  void _openArtist(BuildContext context, String artistId) {
    NavigationHelper.push(context, ArtistScreen(artistId: artistId));
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    NavigationHelper.push(
      context,
      PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name),
    );
  }

  void _playList(BuildContext context, List<Song> songs, {int index = 0}) {
    if (songs.isEmpty) return;
    context.read<PlayerProvider>().playSong(
          songs[index],
          playlist: songs,
          startIndex: index,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _isDesktop;
    final hPad = isDesktop ? 32.0 : YtmSpacing.md;
    final cardSize = isDesktop ? 180.0 : YtmSizes.albumCard;
    final artistSize = isDesktop ? 160.0 : YtmSizes.artistCircle;
    final authProvider = Provider.of<AuthProvider>(context);
    final isOffline = authProvider.state == AuthState.offlineMode;

    return Scaffold(
      backgroundColor: isDark ? YtmColors.bg : YtmColors.lightBg,
      appBar: YtmTopBar(
        showWordmark: true,
        showSearch: true,
        showAvatar: true,
        avatarLetter: authProvider.config?.username ?? 'M',
        onAvatarTap: () =>
            NavigationHelper.push(context, const SettingsScreen()),
        onSearchTap: () =>
            NavigationHelper.push(context, const SearchScreen()),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await Provider.of<LibraryProvider>(context, listen: false).refresh();
        },
        child: Consumer2<LibraryProvider, RecommendationService>(
          builder: (context, library, recommendationService, _) {
            if (library.isLoading && !library.isInitialized) {
              return const _HomeLoading();
            }

            final allSongs = library.cachedAllSongs.isNotEmpty
                ? library.cachedAllSongs
                : library.randomSongs;
            final key = _computeRandomKey(allSongs, recommendationService);

            if (recommendationService.enabled && key.isNotEmpty) {
              if (key != _lastRandomKey) {
                _cachedMixes =
                    recommendationService.generateMixes(allSongs);
                _cachedPersonalized = recommendationService
                    .getPersonalizedFeed(allSongs, limit: 12);
                _cachedListenAgain =
                    recommendationService.getListenAgain(allSongs, limit: 10);
                _cachedTopHits =
                    recommendationService.getTopHits(allSongs, limit: 10);
                _lastRandomKey = key;
              }
            } else {
              _cachedMixes = const {};
              _cachedPersonalized = const [];
              _cachedListenAgain = const [];
              _cachedTopHits = const [];
              _lastRandomKey = '';
            }

            var mixes = _cachedMixes;
            var personalizedFeed = _cachedPersonalized;
            var listenAgain = _cachedListenAgain;
            var topHits = _cachedTopHits;
            var recentAlbums = library.recentAlbums;
            var frequentAlbums = library.frequentAlbums;
            var newestAlbums = library.newestAlbums;
            var playlists = library.playlists;
            var artists = library.artists;

            if (artists.isEmpty && recommendationService.enabled) {
              final topNames =
                  recommendationService.getRecommendedArtists(limit: 10);
              if (topNames.isNotEmpty) {
                artists = topNames
                    .map((name) => Artist(id: 'rec-$name', name: name))
                    .toList();
              }
            }

            if (isOffline) {
              final offline = OfflineService();
              final downloadedIds = offline.getDownloadedSongIds().toSet();
              final downloadedPlaylistIds =
                  offline.downloadedPlaylistIds.value.toSet();
              final downloadedAlbumIds = <String>{};
              for (final song in allSongs) {
                if (downloadedIds.contains(song.id) && song.albumId != null) {
                  downloadedAlbumIds.add(song.albumId!);
                }
              }

              recentAlbums = recentAlbums
                  .where((a) => downloadedAlbumIds.contains(a.id))
                  .toList();
              frequentAlbums = frequentAlbums
                  .where((a) => downloadedAlbumIds.contains(a.id))
                  .toList();
              newestAlbums = newestAlbums
                  .where((a) => downloadedAlbumIds.contains(a.id))
                  .toList();
              playlists = playlists
                  .where((p) => downloadedPlaylistIds.contains(p.id))
                  .toList();

              final offlineMixes = <String, List<Song>>{};
              for (final entry in mixes.entries) {
                final filtered = entry.value
                    .where((s) => downloadedIds.contains(s.id))
                    .toList();
                if (filtered.isNotEmpty) offlineMixes[entry.key] = filtered;
              }
              mixes = offlineMixes;
              personalizedFeed = personalizedFeed
                  .where((s) => downloadedIds.contains(s.id))
                  .toList();
              listenAgain = listenAgain
                  .where((s) => downloadedIds.contains(s.id))
                  .toList();
              topHits =
                  topHits.where((s) => downloadedIds.contains(s.id)).toList();
            }

            final showMusic = _selectedCategory == 'All' ||
                _selectedCategory == 'Music';
            final showMadeForYou = _selectedCategory == 'All' ||
                _selectedCategory == 'MadeForYou';
            final showPlaylists = _selectedCategory == 'All' ||
                _selectedCategory == 'Playlists';
            final yourMixes = Map<String, List<Song>>.of(mixes)
              ..remove('Discover Mix');
            final discoverSongs = mixes['Discover Mix']?.isNotEmpty == true
                ? mixes['Discover Mix']!
                : personalizedFeed;

            // Server-generated playlists (Pignify Watch, Explo, weekly/daily
            // mixes) get their own row and are hidden from "Your playlists".
            final discoveryPattern =
                RegExp(r'pignify|explo|weekly|daily', caseSensitive: false);
            final discoveryPlaylists = playlists
                .where((p) => discoveryPattern.hasMatch(p.name))
                .toList();
            playlists = playlists
                .where((p) => !discoveryPattern.hasMatch(p.name))
                .toList();

            final sections = <Widget>[];
            void addSection(Widget child) {
              sections.add(child);
              sections.add(const SizedBox(height: 24));
            }

            if (showMusic) {
              final listenAlbums =
                  frequentAlbums.isNotEmpty ? frequentAlbums : recentAlbums;
              if (listenAlbums.isNotEmpty) {
                addSection(
                  YtmSection(
                    title: 'Listen again',
                    onMore: () => NavigationHelper.push(
                      context,
                      const AlbumCollectionScreen.recent(),
                    ),
                    cardHeight: cardSize + 64,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    children: listenAlbums.take(12).map((album) {
                      return YtmMediaCard(
                        title: album.name,
                        subtitle: album.artist,
                        coverArt: album.coverArt,
                        size: cardSize,
                        onTap: () => _openAlbum(context, album.id),
                      );
                    }).toList(),
                  ),
                );
              } else if (listenAgain.isNotEmpty) {
                addSection(
                  YtmSection(
                    title: 'Listen again',
                    cardHeight: cardSize + 64,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    children: listenAgain.take(12).map((song) {
                      return YtmMediaCard(
                        title: song.title,
                        subtitle: song.artist,
                        coverArt: song.coverArt,
                        size: cardSize,
                        onTap: () => _playList(context, listenAgain,
                            index: listenAgain.indexOf(song)),
                      );
                    }).toList(),
                  ),
                );
              }
            }

            if (showMadeForYou && yourMixes.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Your mixes',
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: yourMixes.entries.take(6).map((entry) {
                    return YtmMediaCard(
                      title: entry.key,
                      subtitle: '${entry.value.length} songs',
                      coverArt: entry.value.first.coverArt,
                      size: cardSize,
                      onTap: () => _playList(context, entry.value),
                    );
                  }).toList(),
                ),
              );
            }

            if (showMusic && newestAlbums.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'New releases',
                  onMore: () => NavigationHelper.push(
                    context,
                    const AlbumCollectionScreen.newReleases(),
                  ),
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: newestAlbums.take(12).map((album) {
                    return YtmMediaCard(
                      title: album.name,
                      subtitle: album.artist,
                      coverArt: album.coverArt,
                      size: cardSize,
                      onTap: () => _openAlbum(context, album.id),
                    );
                  }).toList(),
                ),
              );
            }

            if (discoveryPlaylists.isEmpty &&
                (showMadeForYou || showMusic) &&
                discoverSongs.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Discover',
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: discoverSongs.take(12).map((song) {
                    return YtmMediaCard(
                      title: song.title,
                      subtitle: song.artist,
                      coverArt: song.coverArt,
                      size: cardSize,
                      onTap: () => _playList(context, discoverSongs,
                          index: discoverSongs.indexOf(song)),
                    );
                  }).toList(),
                ),
              );
            }

            if (showMusic && recentAlbums.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Recently added',
                  onMore: () => NavigationHelper.push(
                    context,
                    const AlbumCollectionScreen.recent(),
                  ),
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: recentAlbums.take(12).map((album) {
                    return YtmMediaCard(
                      title: album.name,
                      subtitle: album.artist,
                      coverArt: album.coverArt,
                      size: cardSize,
                      onTap: () => _openAlbum(context, album.id),
                    );
                  }).toList(),
                ),
              );
            }

            if (showMadeForYou && topHits.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Your top hits',
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: topHits.take(12).map((song) {
                    return YtmMediaCard(
                      title: song.title,
                      subtitle: song.artist,
                      coverArt: song.coverArt,
                      size: cardSize,
                      onTap: () => _playList(context, topHits,
                          index: topHits.indexOf(song)),
                    );
                  }).toList(),
                ),
              );
            }

            if (showPlaylists && discoveryPlaylists.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Discover',
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: discoveryPlaylists.take(12).map((playlist) {
                    return YtmMediaCard(
                      title: playlist.name,
                      subtitle: playlist.songCount != null
                          ? '${playlist.songCount} songs'
                          : 'Playlist',
                      artwork: PlaylistArtwork(
                        playlist: playlist,
                        size: cardSize,
                        borderRadius: YtmRadii.card,
                      ),
                      size: cardSize,
                      onTap: () => _openPlaylist(context, playlist),
                    );
                  }).toList(),
                ),
              );
            }

            if (showPlaylists && playlists.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Your playlists',
                  onMore: () => NavigationHelper.push(
                    context,
                    const PlaylistsScreen(),
                  ),
                  cardHeight: cardSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: playlists.take(12).map((playlist) {
                    return YtmMediaCard(
                      title: playlist.name,
                      subtitle: 'Playlist',
                      artwork: PlaylistArtwork(
                        playlist: playlist,
                        size: cardSize,
                        borderRadius: YtmRadii.card,
                      ),
                      size: cardSize,
                      onTap: () => _openPlaylist(context, playlist),
                    );
                  }).toList(),
                ),
              );
            }

            if (showMusic && artists.isNotEmpty) {
              addSection(
                YtmSection(
                  title: 'Artists you love',
                  cardHeight: artistSize + 64,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: artists.take(10).map((artist) {
                    final coverArt = artist.coverArt ??
                        artist.artistImageUrl ??
                        (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
                    return YtmMediaCard(
                      title: artist.name,
                      subtitle: 'Artist',
                      coverArt: coverArt,
                      round: true,
                      size: artistSize,
                      onTap: () => _openArtist(context, artist.id),
                    );
                  }).toList(),
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    itemCount: 4,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: YtmSpacing.xs),
                    itemBuilder: (context, index) {
                      const chips = [
                        ('All', 'All'),
                        ('Music', 'Music'),
                        ('MadeForYou', 'Made For You'),
                        ('Playlists', 'Playlists'),
                      ];
                      final (key, label) = chips[index];
                      return YtmFilterChip(
                        label: label,
                        selected: _selectedCategory == key,
                        onTap: () => setState(() => _selectedCategory = key),
                      );
                    },
                  ),
                ),
                const SizedBox(height: YtmSpacing.xs),
                if (sections.isEmpty)
                  _HomeEmpty(
                    error: library.error,
                    onRetry: () => library.refresh(),
                  )
                else
                  ...sections,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 96),
        child: CircularProgressIndicator(color: Colors.white70),
      ),
    );
  }
}

class _HomeEmpty extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const _HomeEmpty({this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final secondary =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          Icon(
            error == null ? Icons.music_note_rounded : Icons.cloud_off_rounded,
            size: 48,
            color: secondary,
          ),
          const SizedBox(height: 16),
          Text(
            error == null ? 'No music yet' : 'Could not load your library',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Add music to Navidrome and pull to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: fg,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
