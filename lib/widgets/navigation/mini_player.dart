import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:musly/models/artist_ref.dart';
import 'package:musly/models/radio_station.dart';
import 'package:musly/models/song.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/screens/player/now_playing_screen.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/ytm_tokens.dart';
import 'package:musly/utils/screen_helper.dart';
import 'package:musly/widgets/common/album_artwork.dart';
import 'package:musly/widgets/modals/song_options_modal.dart';

/// YouTube-Music-style mini player: 48 pt artwork, two lines of text, play/pause
/// and next, with a 2 pt progress line. Tap or swipe up opens Now Playing.
class MiniPlayer extends StatelessWidget {
  /// Optional override; when null the mini player opens Now Playing itself.
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop && ScreenHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) =>
          (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
      builder: (context, data, _) {
        final (song, radio, isPlayingRadio) = data;
        if (song == null && !isPlayingRadio) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? YtmColors.surfaceHigh : YtmColors.lightSurface;
        final fg = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
        final secondary =
            isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;

        final title = isPlayingRadio ? (radio?.name ?? 'Radio') : song!.title;
        final subtitle = isPlayingRadio
            ? 'Internet Radio • LIVE'
            : _artistLabel(song!);

        void openPlayer() {
          if (onTap != null) {
            onTap!();
            return;
          }
          if (song == null) return;
          final subsonic = context.read<SubsonicService>();
          final coverUrl = song.coverArt != null
              ? subsonic.getCoverArtUrl(song.coverArt, size: 800)
              : null;
          final imageProvider = (coverUrl != null && coverUrl.isNotEmpty)
              ? CachedNetworkImageProvider(coverUrl) as ImageProvider
              : const AssetImage('assets/logo.png') as ImageProvider;
          final topPadding = MediaQuery.of(context).padding.top;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black54,
            constraints: const BoxConstraints(maxWidth: double.infinity),
            builder: (_) => NowPlayingScreen(
              topPadding: topPadding,
              image: imageProvider,
              title: song.title,
              artist: _artistLabel(song),
              heroTag: 'cover_${song.id}',
              song: song,
            ),
          );
        }

        return RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openPlayer,
            onLongPress: song != null
                ? () => SongOptionsModal.show(context, song)
                : null,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -250) openPlayer();
            },
            child: Container(
              height: YtmSizes.miniPlayer + YtmSizes.miniPlayerProgress,
              color: bg,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: YtmSpacing.md,
                      ),
                      child: Row(
                        children: [
                          if (isPlayingRadio)
                            const _RadioArtwork()
                          else
                            AlbumArtwork(
                              coverArt: song!.coverArt,
                              size: 48,
                              borderRadius: YtmRadii.row,
                            ),
                          const SizedBox(width: YtmSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: YtmText.listTitle.copyWith(color: fg),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: YtmText.listSubtitle
                                      .copyWith(color: secondary),
                                ),
                              ],
                            ),
                          ),
                          _MiniControls(color: fg),
                        ],
                      ),
                    ),
                  ),
                  _MiniProgressBar(color: fg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _artistLabel(Song song) {
    if (song.artistParticipants?.isNotEmpty == true) {
      return song.artistParticipants!.map((a) => a.name).join(', ');
    }
    if (song.artist != null && song.artist!.isNotEmpty) {
      return ArtistRef.splitArtistNames(song.artist!).join(', ');
    }
    return '';
  }
}

class _MiniControls extends StatelessWidget {
  final Color color;

  const _MiniControls({required this.color});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool)>(
      selector: (_, p) => (p.isPlaying, p.hasNext),
      builder: (context, data, _) {
        final (isPlaying, hasNext) = data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: provider.togglePlayPause,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
              ),
              color: color,
            ),
            IconButton(
              onPressed: hasNext ? provider.skipNext : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.skip_next_rounded, size: 26),
              color: color,
            ),
          ],
        );
      },
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final Color color;

  const _MiniProgressBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (Duration, int?, bool)>(
      selector: (_, p) =>
          (p.duration, p.currentSong?.duration, p.isPlayingRadio),
      builder: (context, data, _) {
        final (duration, songDurationSec, isRadio) = data;
        if (isRadio) {
          return Container(
            height: YtmSizes.miniPlayerProgress,
            color: color.withValues(alpha: 0.18),
          );
        }

        final totalMs = duration.inMilliseconds > 0
            ? duration.inMilliseconds
            : (songDurationSec != null && songDurationSec > 0
                ? songDurationSec * 1000
                : 0);
        final provider = context.read<PlayerProvider>();

        return StreamBuilder<Duration>(
          stream: provider.positionStream,
          initialData: provider.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? provider.position;
            final progress = totalMs > 0
                ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                : 0.0;
            final clean = progress.isNaN || progress.isInfinite ? 0.0 : progress;

            return Container(
              height: YtmSizes.miniPlayerProgress,
              color: color.withValues(alpha: 0.18),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clean,
                child: Container(color: color),
              ),
            );
          },
        );
      },
    );
  }
}

class _RadioArtwork extends StatelessWidget {
  const _RadioArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(YtmRadii.row),
      ),
      child: const Icon(Icons.radio, color: Colors.white, size: 24),
    );
  }
}
