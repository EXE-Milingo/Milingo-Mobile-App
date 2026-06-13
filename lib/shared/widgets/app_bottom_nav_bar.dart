import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';

const _kActive = Color(0xFFFF6A00);
const _kInactive = Color(0xFF94A3B8);

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
        context.push(AppConstants.snapAndLearnRoute);
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
        label: 'Trang chủ',
        assetPath: 'assets/svg/homescreen.svg',
      ),
      _BottomNavItem(
        label: 'AI Tutor',
        assetPath: 'assets/svg/new-ai-tutor.svg',
      ),
      _BottomNavItem(
        label: '',
        assetPath: 'assets/svg/snap.svg',
        isCenter: true,
      ),
      _BottomNavItem(
        label: 'Ôn tập',
        assetPath: 'assets/svg/new-review.svg',
      ),
      _BottomNavItem(
        label: 'Hồ sơ',
        assetPath: 'assets/svg/new-profile/profile-account.svg',
      ),
    ];

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: Colors.transparent,
      child: SizedBox(
        height: bottomInset + 98,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: math.min(MediaQuery.sizeOf(context).width - 28, 360),
                height: 78,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return Expanded(
                      child: _BottomNavTile(
                        item: item,
                        selected: index == currentIndex,
                        onTap: () => _goToTab(context, index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.label,
    required this.assetPath,
    this.isCenter = false,
  });

  final String label;
  final String assetPath;
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
    if (item.isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: 112,
                maxHeight: 112,
                child: SvgPicture.asset(
                  item.assetPath,
                  width: 106,
                  height: 106,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final color = selected ? _kActive : _kInactive;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SvgPicture.asset(
                item.assetPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  height: 1.2,
                  letterSpacing: 0.334,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
