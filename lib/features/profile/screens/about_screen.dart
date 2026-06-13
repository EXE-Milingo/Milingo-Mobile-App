import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/profile/widgets/about_screen_components.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const AboutBackground(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: Column(
                children: [
                  AboutHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 20),
                  const AboutHero(),
                  const AboutMissionCard(),
                  const AboutSectionTitle('Đội ngũ phát triển'),
                  const AboutTeamCard(),
                  const AboutSectionTitle('Liên kết'),
                  AboutLinksCard(
                    onWebsiteTap: _openWebsite,
                    onTermsTap: () =>
                        context.push(AppConstants.termsOfServiceRoute),
                    onPrivacyTap: () =>
                        context.push(AppConstants.termsOfServiceRoute),
                  ),
                  const AboutSectionTitle('Mạng xã hội'),
                  AboutSocialButtons(
                    onTwitterTap: () {},
                    onInstagramTap: () {},
                    onGithubTap: () {},
                  ),
                  const AboutCopyright(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openWebsite() async {
    final uri = Uri.parse(AppConstants.milingoWebBaseUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
