import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// ✅ NEW — Help & Support screen: FAQ + Contact Us.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      'How do I become eligible to donate again after donating?',
      'There must be at least 90 days between donations. Your Eligibility '
          'status on the Donor Dashboard shows exactly when you\'ll be '
          'eligible again — you\'ll also get a notification on that day.',
    ),
    _FaqItem(
      'Why can\'t I see a donor\'s phone number directly?',
      'To protect donors from having their number visible to everyone, '
          'numbers are only shared when you tap "Call Donor" on a specific '
          'match. Every lookup is logged for accountability.',
    ),
    _FaqItem(
      'My account is stuck on "Pending" — what does that mean?',
      'New accounts are reviewed before activation, usually within 24-48 '
          'hours. You\'ll receive an email once your account is approved. '
          'If it\'s been longer, contact us below.',
    ),
    _FaqItem(
      'How does the SOS emergency alert work?',
      'When a receiver sends an SOS, nearby approved donors with a '
          'matching blood group and "Available" status are notified '
          'immediately via push notification (and SMS as a backup if push '
          'fails to deliver). Responding is always voluntary.',
    ),
    _FaqItem(
      'How do I stop appearing in donor searches?',
      'Go to Settings → Availability and turn off "Available to Donate." '
          'You can also turn off Location Sharing separately if you don\'t '
          'want to appear in nearby searches at all.',
    ),
    _FaqItem(
      'I think someone is misusing the app — what do I do?',
      'Use the "Report" flag icon on the relevant request or profile. '
          'Reports go straight to our admin review queue — please don\'t '
          'confront other users directly.',
    ),
    _FaqItem(
      'How do reward points work?',
      'You earn points each time a donation you made is confirmed by the '
          'receiver. Points are shown on your Rewards screen along with '
          'your current tier/level.',
    ),
  ];

  Future<void> _contactUs(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final subject = Uri.encodeComponent('Smart Blood Bank — Support Request');
    final body = Uri.encodeComponent(
      'Describe your issue here:\n\n\n'
          '---\n'
          'App version: ${AppConstants.appVersion}\n'
          'Account email: ${user?.email ?? "not signed in"}\n'
          'User ID: ${user?.uid ?? "n/a"}',
    );
    final uri = Uri.parse(
      'mailto:${AppConstants.supportEmail}?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open your email app. Email us directly at '
                '${AppConstants.supportEmail}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Contact card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.privacyPolicyContactNote,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _contactUs(context),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Contact Us'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
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
                for (int i = 0; i < _faqs.length; i++) ...[
                  ExpansionTile(
                    title: Text(
                      _faqs[i].question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _faqs[i].answer,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  if (i != _faqs.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}