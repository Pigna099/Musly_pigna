import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musly/theme/ytm_tokens.dart';

/// One destination in [YtmBottomNav].
class YtmNavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const YtmNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// YouTube-Music-style bottom navigation: flat, label under icon, white active
/// state, no indicator pill.
class YtmBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<YtmNavDestination> destinations;

  const YtmBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? YtmColors.bg : YtmColors.lightBg;
    final active = isDark ? YtmColors.textPrimary : YtmColors.lightTextPrimary;
    final inactive =
        isDark ? YtmColors.textSecondary : YtmColors.lightTextSecondary;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            color: isDark ? YtmColors.divider : YtmColors.lightDivider,
          ),
          SizedBox(
            height: YtmSizes.bottomNav,
            child: Row(
              children: List.generate(destinations.length, (index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: Semantics(
                    selected: isSelected,
                    button: true,
                    label: destination.label,
                    child: InkResponse(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDestinationSelected(index);
                      },
                      radius: 32,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected
                                ? destination.activeIcon
                                : destination.icon,
                            size: 24,
                            color: isSelected ? active : inactive,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: YtmText.navLabel.copyWith(
                              color: isSelected ? active : inactive,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: safeBottom),
        ],
      ),
    );
  }
}
