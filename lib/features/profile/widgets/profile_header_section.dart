import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:milingo/features/profile/widgets/profile_view_data.dart';

class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({
    required this.data,
    super.key,
  });

  final ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Hồ sơ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ProfileHeaderColors.orange,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 156,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                child: _ProfileAvatar(data: data),
              ),
              Positioned(
                top: 124,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      data.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ProfileHeaderColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      data.memberSince,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ProfileHeaderColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.data});

  final ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _ProfileHeaderColors.orange.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: _ProfileHeaderColors.orange.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: ClipOval(child: _AvatarImage(data: data)),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.data});

  final ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    final localPath = data.localAvatarPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = io.File(localPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    final photoUrl = data.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFallback(name: data.displayName),
      );
    }

    return _AvatarFallback(name: data.displayName);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'M' : name.trim()[0].toUpperCase();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFE2CC)),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _ProfileHeaderColors.orange,
            fontSize: 42,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderColors {
  static const orange = Color(0xFFFF6A00);
  static const text = Color(0xFF1D1814);
  static const muted = Color(0x8C1D1814);
}
