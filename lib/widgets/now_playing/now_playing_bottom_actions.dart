import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom tabs of Now Playing, in the classic YouTube Music arrangement:
/// UP NEXT / LYRICS / RELATED.
class NowPlayingBottomActions extends StatelessWidget {
  final VoidCallback onLyricsTap;
  final VoidCallback onQueueTap;
  final VoidCallback onRelatedTap;
  final bool isLyricsActive;
  final bool isQueueActive;
  final bool isRelatedActive;

  const NowPlayingBottomActions({
    super.key,
    required this.onLyricsTap,
    required this.onQueueTap,
    required this.onRelatedTap,
    this.isLyricsActive = false,
    this.isQueueActive = false,
    this.isRelatedActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        children: [
          _Tab(
            label: 'UP NEXT',
            active: isQueueActive,
            onTap: onQueueTap,
          ),
          _Tab(
            label: 'LYRICS',
            active: isLyricsActive,
            onTap: onLyricsTap,
          ),
          _Tab(
            label: 'RELATED',
            active: isRelatedActive,
            onTap: onRelatedTap,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: 32,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: active ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
