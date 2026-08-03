import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'legal/legal_content.dart';
import 'legal/legal_document_screen.dart';

/// ✅ NEW — About screen: app version, developer credit, share app, and
/// open-source licenses (uses Flutter's built-in license page — no extra
/// dependency needed since every package's LICENSE file is already
/// bundled into the app by the build tool).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _shareApp() {
    // No public store link yet — update this once the app is published,
    // e.g. 'Download Smart Blood Bank: https://play.google.com/store/apps/details?id=com.usmanch.bloodbank'
    Share.share(
      'Check out Smart Blood Bank — an app that connects blood donors '
          'with people who need blood, nearby and in emergencies.',
      subject: 'Smart Blood Bank',
    );
  }
  void _showRatingDialog(BuildContext context) {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Rate Smart Blood Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate your experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(
                            () => selectedStars = starIndex),
                    icon: Icon(
                      starIndex <= selectedStars
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStars == 0
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      selectedStars >= 4
                          ? 'Thanks for the $selectedStars★ rating! 🎉'
                          : 'Thanks for the feedback — we\'ll keep '
                          'improving. 🙏',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App identity card ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bloodtype,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share App'),
                  onTap: _shareApp,
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Rate Us'),
                  onTap: () => _showRatingDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentScreen(
                        title: 'Terms of Service',
                        content: LegalContent.termsOfService,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentScreen(
                        title: 'Privacy Policy',
                        content: LegalContent.privacyPolicy,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.bloodtype,
                          color: AppColors.primaryRed, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'Made with ❤️ by ${AppConstants.developerName}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}