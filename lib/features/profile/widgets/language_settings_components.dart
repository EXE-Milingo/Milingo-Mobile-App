import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LanguageSettingsOption {
  final String code;
  final String label;
  final String? flagAsset;
  final String? flagEmoji;

  const LanguageSettingsOption({
    required this.code,
    required this.label,
    this.flagAsset,
    this.flagEmoji,
  });
}

class LanguageSettingsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const LanguageSettingsHeader({
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF1D1814),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Ngôn ngữ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF1D1814),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageSectionTitle extends StatelessWidget {
  final String title;

  const LanguageSectionTitle({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: const Color(0xFF1D1814).withValues(alpha: 0.55),
          height: 1.4,
        ),
      ),
    );
  }
}

class LanguageCardContainer extends StatelessWidget {
  final List<Widget> children;

  const LanguageCardContainer({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1814).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class LanguageRowItem extends StatelessWidget {
  final LanguageSettingsOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final String? customIconAsset;

  const LanguageRowItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.customIconAsset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: customIconAsset != null
                      ? const Color(0xFFFF6A00).withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
                child: customIconAsset != null
                    ? Center(
                        child: SvgPicture.asset(
                          customIconAsset!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      )
                    : (option.flagAsset != null
                        ? Image.asset(
                            option.flagAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  option.flagEmoji ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              option.flagEmoji ?? '🏳️',
                              style: const TextStyle(fontSize: 20),
                            ),
                          )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1D1814),
                    height: 1.5,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFFFF6A00),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
