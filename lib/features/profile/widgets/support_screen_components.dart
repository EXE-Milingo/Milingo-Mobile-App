import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';
import 'package:url_launcher/url_launcher.dart';

/// Collapsible FAQ Item Widget
class FaqAccordionTile extends StatefulWidget {
  const FaqAccordionTile({
    required this.question,
    required this.answer,
    super.key,
  });

  final String question;
  final String answer;

  @override
  State<FaqAccordionTile> createState() => _FaqAccordionTileState();
}

class _FaqAccordionTileState extends State<FaqAccordionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1814).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Orange help icon badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6A00).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.help_outline_rounded,
                              color: Color(0xFFFF6A00),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Question text
                        Expanded(
                          child: Text(
                            widget.question,
                            style: const TextStyle(
                              color: Color(0xFF1D1814),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Expand/collapse arrow indicator
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFB8A8A0),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
                      child: Text(
                        widget.answer,
                        style: const TextStyle(
                          color: Color(0xFF6B6259),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card containing Contact and Support actions
class ContactOptionsCard extends StatelessWidget {
  const ContactOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1814).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            const _ContactDropdownTile(
              label: 'Liên hệ hỗ trợ',
              assetPath: 'assets/svg/new-profile/mail.svg',
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x0D000000)),
            _ContactTile(
              label: 'Điều khoản & Bảo mật',
              assetPath: 'assets/svg/new-profile/term_and_service.svg',
              onTap: () => context.push(AppConstants.termsOfServiceRoute),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful tile for dropdown email support info
class _ContactDropdownTile extends StatefulWidget {
  const _ContactDropdownTile({
    required this.label,
    required this.assetPath,
  });

  final String label;
  final String assetPath;

  @override
  State<_ContactDropdownTile> createState() => _ContactDropdownTileState();
}

class _ContactDropdownTileState extends State<_ContactDropdownTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ProfileSvgIcon(
                        widget.assetPath,
                        size: 17,
                        color: const Color(0xFFFF6A00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Color(0xFF1D1814),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFB8A8A0),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(64, 0, 16, 16),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF6B6259),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Nếu bạn có nhu cầu hỗ trợ gì, xin hãy liên hệ với chúng tôi qua email sau: ',
                        ),
                        TextSpan(
                          text: 'milingo.vn@gmail.com',
                          style: const TextStyle(
                            color: Color(0xFFFF6A00),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _handleEmailTap(context),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailTap(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'milingo.vn@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Yêu cầu hỗ trợ - MiLingo',
      }),
    );
    // Copy email to clipboard first
    await Clipboard.setData(const ClipboardData(text: 'milingo.vn@gmail.com'));

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã mở ứng dụng email và sao chép email hỗ trợ vào bộ nhớ tạm!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw 'Could not launch';
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép email milingo.vn@gmail.com vào bộ nhớ tạm!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback onTap;

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
              // Orange background circular icon container
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ProfileSvgIcon(
                  assetPath,
                  size: 17,
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 12),
              // Option title label
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1D1814),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB8A8A0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
