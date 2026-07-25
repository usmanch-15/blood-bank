import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

/// ✅ PHASE 2 — Help, Support & Legal
/// Adjust the URLs/email below to your real ones.
class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  static const supportEmail = 'support@yourapp.com';
  static const privacyPolicyUrl = 'https://yourapp.com/privacy';
  static const termsUrl = 'https://yourapp.com/terms';
  static const appVersion = '1.0.0'; // TODO: pull from package_info_plus if you add it

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & About'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const _SectionHeader('Help & Support'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text(supportEmail),
            onTap: () => launchUrl(Uri.parse('mailto:$supportEmail')),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            onTap: () {
              // TODO: navigate to an FAQ screen or open a URL
            },
          ),
          const _SectionHeader('About & Legal'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text(appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => launchUrl(Uri.parse(privacyPolicyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => launchUrl(Uri.parse(termsUrl)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryRed,
        ),
      ),
    );
  }
}