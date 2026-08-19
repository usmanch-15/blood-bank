import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../controllers/theme_controller.dart';
import '../../services/settings_service.dart';
import '../auth/login_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'change_email_screen.dart';

/// ✅ PHASE 1 — Settings Screen
///
/// Covers:
///  - Profile (name, phone, blood group, address)
///  - Account & Security (change password, logout, delete account)
///  - Notifications (master toggle + 3 category toggles)
///  - Donor availability toggle
///  - Location sharing toggle
///
/// Uses SettingsService for all Firestore/Auth reads & writes.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _isSaving = false;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<dynamic>(
        stream: _settingsService.profileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !(snapshot.data.exists as bool)) {
            return const Center(child: Text('Profile not found.'));
          }

          final data = Map<String, dynamic>.from(snapshot.data.data() ?? {});
          final isDonor = data['isDonor'] == true || data['role'] == 'donor';

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _sectionHeader('Profile', Icons.person_outline_rounded),
              _ProfileTile(data: data, settingsService: _settingsService),

              const SizedBox(height: 8),
              _sectionHeader('Notifications', Icons.notifications_outlined),
              _NotificationsTile(
                data: data,
                settingsService: _settingsService,
                onSnack: _showSnack,
              ),

              if (isDonor) ...[
                const SizedBox(height: 8),
                _sectionHeader('Availability', Icons.favorite_outline),
                _AvailabilityTile(
                  data: data,
                  settingsService: _settingsService,
                  onSnack: _showSnack,
                ),
              ],

              const SizedBox(height: 8),
              _sectionHeader('Location & Privacy', Icons.location_on_outlined),
              _LocationSharingTile(
                data: data,
                settingsService: _settingsService,
                onSnack: _showSnack,
              ),

              const SizedBox(height: 8),
              _sectionHeader('Appearance', Icons.palette_outlined),
              const _AppearanceTile(),

              const SizedBox(height: 8),
              _sectionHeader('Support & About', Icons.help_outline_rounded),
              const _SupportAboutTile(),

              const SizedBox(height: 8),
              _sectionHeader('Account & Security', Icons.lock_outline_rounded),
              _AccountSecurityTile(
                settingsService: _settingsService,
                onSnack: _showSnack,
                isSaving: _isSaving,
                setSaving: (v) => setState(() => _isSaving = v),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ✅ POLISH — icon + bolder label instead of a bare line of red text,
  // so each section reads as a distinct group at a glance.
  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ PROFILE ═══════════════════════════

class _ProfileTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final SettingsService settingsService;

  const _ProfileTile({required this.data, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(data['name']?.toString() ?? 'No name set'),
            subtitle: Text(data['email']?.toString() ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditProfileSheet(context),
            ),
          ),
          StreamBuilder<String?>(
            stream: settingsService.phoneStream(),
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone'),
                subtitle: Text(
                  (snapshot.data == null || snapshot.data!.isEmpty)
                      ? 'Not set'
                      : snapshot.data!,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Blood Group'),
            subtitle: Text(data['bloodGroup']?.toString() ?? 'Not set'),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Address'),
            subtitle: Text(data['address']?.toString() ?? 'Not set'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfileSheet(BuildContext context) async {
    final nameCtrl = TextEditingController(text: data['name']?.toString());
    // ✅ phoneNumber is no longer in `data` (top-level doc) — fetch it
    // from the private subcollection before opening the sheet.
    final currentPhone = await settingsService.getPhoneOnce();
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    final addressCtrl =
    TextEditingController(text: data['address']?.toString());
    String bloodGroup = data['bloodGroup']?.toString() ?? 'O+';
    const bloodGroups = [
      'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
    ];

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: bloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                    ),
                    items: bloodGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => bloodGroup = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await settingsService.updateProfile(
                          name: nameCtrl.text,
                          phoneNumber: phoneCtrl.text,
                          bloodGroup: bloodGroup,
                          address: addressCtrl.text,
                        );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      } catch (e) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text('Failed to save: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════ NOTIFICATIONS ═══════════════════════════

class _NotificationsTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final SettingsService settingsService;
  final void Function(String, {bool isError}) onSnack;

  const _NotificationsTile({
    required this.data,
    required this.settingsService,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final masterEnabled = data['notificationsEnabled'] != false; // default true
    final prefs =
    Map<String, dynamic>.from(data['notificationPrefs'] ?? {});
    final sosAlerts = prefs['sosAlerts'] != false;
    final rewardUpdates = prefs['rewardUpdates'] != false;
    final adminAnnouncements = prefs['adminAnnouncements'] != false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Master switch for all notifications'),
            value: masterEnabled,
            activeThumbColor: AppColors.primaryRed,
            onChanged: (v) async {
              await settingsService.updateNotificationPref(masterEnabled: v);
              onSnack(
                v
                    ? 'Notifications turned on'
                    : 'Notifications turned off — you will not receive SOS alerts.',
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('SOS Emergency Alerts'),
            value: masterEnabled && sosAlerts,
            activeThumbColor: AppColors.primaryRed,
            onChanged: masterEnabled
                ? (v) async {
              await settingsService.updateNotificationPref(
                sosAlerts: v,
              );
            }
                : null,
          ),
          SwitchListTile(
            title: const Text('Reward Updates'),
            value: masterEnabled && rewardUpdates,
            activeThumbColor: AppColors.primaryRed,
            onChanged: masterEnabled
                ? (v) async {
              await settingsService.updateNotificationPref(
                rewardUpdates: v,
              );
            }
                : null,
          ),
          SwitchListTile(
            title: const Text('Admin Announcements'),
            value: masterEnabled && adminAnnouncements,
            activeThumbColor: AppColors.primaryRed,
            onChanged: masterEnabled
                ? (v) async {
              await settingsService.updateNotificationPref(
                adminAnnouncements: v,
              );
            }
                : null,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ AVAILABILITY ═══════════════════════════

class _AvailabilityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final SettingsService settingsService;
  final void Function(String, {bool isError}) onSnack;

  const _AvailabilityTile({
    required this.data,
    required this.settingsService,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = data['isAvailable'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: SwitchListTile(
        title: const Text('Available to Donate'),
        subtitle: Text(
          isAvailable
              ? 'You will appear in nearby donor searches.'
              : 'You are hidden from nearby donor searches.',
        ),
        value: isAvailable,
        activeThumbColor: AppColors.primaryRed,
        onChanged: (v) async {
          await settingsService.setAvailability(v);
          onSnack(
            v
                ? 'You are now marked as Available.'
                : 'You are now marked as Unavailable.',
          );
        },
      ),
    );
  }
}

// ═══════════════════════════ LOCATION SHARING ═══════════════════════════

class _LocationSharingTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final SettingsService settingsService;
  final void Function(String, {bool isError}) onSnack;

  const _LocationSharingTile({
    required this.data,
    required this.settingsService,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final locationEnabled = data['locationSharingEnabled'] != false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Share My Location'),
            subtitle: const Text(
              'Needed so nearby blood requests can find you during emergencies.',
            ),
            value: locationEnabled,
            activeThumbColor: AppColors.primaryRed,
            onChanged: (v) async {
              await settingsService.setLocationSharing(v);
              onSnack(
                v
                    ? 'Location sharing enabled.'
                    : 'Location sharing disabled — you will not appear in nearby searches until re-enabled.',
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'We only use your location to match you with nearby blood '
                  'requests during emergencies. You can turn this off anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ APPEARANCE ═══════════════════════════

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile();

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  void _openPicker(BuildContext context, ThemeController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'App Theme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  value: mode,
                  // ignore: deprecated_member_use
                  groupValue: controller.themeMode,
                  activeColor: AppColors.primaryRed,
                  secondary: Icon(_icon(mode)),
                  title: Text(_label(mode)),
                  // ignore: deprecated_member_use
                  onChanged: (v) {
                    if (v != null) controller.setThemeMode(v);
                    Navigator.pop(sheetContext);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(_icon(themeController.themeMode)),
        title: const Text('Theme'),
        subtitle: Text(_label(themeController.themeMode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openPicker(context, themeController),
      ),
    );
  }
}

// ═══════════════════════════ SUPPORT & ABOUT ═══════════════════════════

class _SupportAboutTile extends StatelessWidget {
  const _SupportAboutTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('FAQs and contact us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version, Terms, Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ ACCOUNT & SECURITY ═══════════════════════════

class _AccountSecurityTile extends StatelessWidget {
  final SettingsService settingsService;
  final void Function(String, {bool isError}) onSnack;
  final bool isSaving;
  final void Function(bool) setSaving;

  const _AccountSecurityTile({
    required this.settingsService,
    required this.onSnack,
    required this.isSaving,
    required this.setSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openChangePasswordSheet(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Change Email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download My Data'),
            subtitle: const Text('Export your profile & donation history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _downloadMyData(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Logout'),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMyData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Preparing your data...')),
          ],
        ),
      ),
    );
    try {
      final export = await settingsService.exportUserData();
      if (context.mounted) Navigator.pop(context); // close loading dialog
      await Share.share(export, subject: 'My Smart Blood Bank Data');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
        onSnack('Could not export data: $e', isError: true);
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await settingsService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently disable your account. This action cannot '
              'be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await settingsService.deleteAccount();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                onSnack(
                  'Could not delete account: please logout and login '
                      'again, then retry. ($e)',
                  isError: true,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        setSheetState(
                              () => error = 'New passwords do not match.',
                        );
                        return;
                      }
                      try {
                        await settingsService.changePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          onSnack('Password changed successfully.');
                        }
                      } catch (e) {
                        setSheetState(
                              () => error = 'Failed to change password: $e',
                        );
                      }
                    },
                    child: const Text(
                      'Update Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}