import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSvgIcon extends StatelessWidget {
  const ProfileSvgIcon(
    this.assetPath, {
    this.size = 18,
    this.color,
    super.key,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
