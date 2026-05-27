import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    super.key,
  });

  final int currentIndex;

  void _goToTab(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go(AppConstants.homeRoute);
        return;
      case 1:
        context.go(AppConstants.flashcardsRoute);
        return;
      case 2:
        context.go(AppConstants.snapAndLearnRoute);
        return;
      case 3:
        context.go(AppConstants.leaderboardRoute);
        return;
      case 4:
        context.go(AppConstants.profileRoute);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      _BottomNavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _BottomNavItem(
        label: 'Vocabulary',
        assetPath: 'assets/svg/review.svg',
      ),
      _BottomNavItem(
        label: 'Snap',
        assetPath: 'assets/svg/Camera Icon.svg',
        isCenter: true,
      ),
      _BottomNavItem(
        label: 'Progress',
        icon: Icons.trending_up_rounded,
        activeIcon: Icons.trending_up_rounded,
      ),
      _BottomNavItem(
        label: 'Profile',
        assetPath: 'assets/svg/personalize.svg',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: _BottomNavTile(
                  item: items[index],
                  selected: selected,
                  onTap: () => _goToTab(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.assetPath,
    this.isCenter = false,
  });

  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final String? assetPath;
  final bool isCenter;
}

class _BottomNavTile extends StatelessWidget {
  const _BottomNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryColor : const Color(0xFF9E9E9E);

    if (item.isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFC58F),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF7A00),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        item.assetPath!,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 44 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: item.isCenter ? 46 : 38,
                    height: item.isCenter ? 38 : 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(item.isCenter ? 18 : 12),
                    ),
                    child: Center(
                      child: item.assetPath == null
                          ? Icon(
                              selected ? (item.activeIcon ?? item.icon) : item.icon,
                              color: color,
                              size: item.isCenter ? 26 : 24,
                            )
                          : SvgPicture.asset(
                              item.assetPath!,
                              width: item.isCenter ? 23 : 21,
                              height: item.isCenter ? 23 : 21,
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
