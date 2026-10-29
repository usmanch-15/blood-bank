import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/workflow_service.dart';
import '../../utils/feedback.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/donor_awareness.dart';
import '../../widgets/premium_states.dart';
import '../notification/notification_history_screen.dart';
import '../requests/request_tracking_screen.dart';
import '../settings/settings_screen.dart';
import 'blood_requests_hub.dart';
import 'donor_profile_screen.dart';
import 'donation_history_screen.dart';
import 'rewards_screen.dart';
import 'eligibility_status_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});
  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  late Future<Map<String, dynamic>> _nearby, _invitations;
  late Stream<Map<String, dynamic>> _active;
  late Future<int?> _donations;
  bool _saving = false;
  int _refreshKey = 0;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<Map<String, dynamic>> _fetch(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      return await WorkflowService.call(name, data);
    } catch (e) {
      return {'loadError': AppFeedback.message(e)};
    }
  }

  Future<int?> _countDonations() async {
    try {
      return (await FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: _uid)
              .count()
              .get())
          .count;
    } catch (_) {
      return null;
    }
  }

  void _reload() {
    _active = _watchActive();
    _nearby = _fetch('discoverRequests', {'radiusKm': 25});
    _invitations = _fetch('donorInvitations');
    _donations = _countDonations();
  }

  Stream<Map<String, dynamic>> _watchActive() async* {
    yield await _loadActive();
    yield* Stream.periodic(
      const Duration(seconds: 30),
    ).asyncMap((_) => _loadActive());
  }

  Future<Map<String, dynamic>> _loadActive() async {
    String? cursor;
    do {
      final page = await WorkflowService.call('participantRequests', {
        'mode': 'active',
        if (cursor != null) 'cursor': cursor,
      });
      // An expired legacy page can be empty while a later page is active.
      cursor = page['cursor'] as String?;
      if ((page['items'] as List).isNotEmpty || cursor == null) return page;
    } while (true);
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshKey++;
      _reload();
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  Future<void> _profile() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (mounted && doc.exists) {
        await _go(DonorProfileScreen(userData: doc.data()!));
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    }
  }

  void _requests([int tab = 0]) => _go(BloodRequestsHub(initialIndex: tab));
  Future<void> _availability(bool value) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'isAvailable': value,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _refresh();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview(
    Future<Map<String, dynamic>> future, {
    required bool invitations,
  }) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const PremiumLoading(rows: 1);
      }
      if (snap.hasError || snap.data?['loadError'] != null) {
        return DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snap.data?['loadError'] as String? ??
                    AppFeedback.message(snap.error!),
              ),
              TextButton(
                onPressed: _refresh,
                child: Text(
                  dashboardText(context, 'Retry', 'دوبارہ کوشش کریں'),
                ),
              ),
            ],
          ),
        );
      }
      final items = (snap.data?['items'] as List? ?? []);
      if (items.isEmpty) {
        return DashboardPanel(
          child: Row(
            children: [
              Icon(
                invitations
                    ? Icons.mark_email_read_outlined
                    : Icons.travel_explore,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dashboardText(
                    context,
                    invitations
                        ? 'No pending invitations. We will let you know when someone asks for your help.'
                        : 'No matches within 25 km. Check your availability and location, or expand your search.',
                    invitations
                        ? 'ابھی کوئی دعوت نہیں۔ نئی دعوت آنے پر اطلاع ملے گی۔'
                        : '۲۵ کلومیٹر میں کوئی درخواست نہیں۔ اپنی دستیابی اور مقام دیکھیں یا تلاش کا دائرہ بڑھائیں۔',
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        children:
            items.take(invitations ? 1 : 2).map((item) {
              final d = Map<String, dynamic>.from(item);
              return OpportunityCard(
                data: d,
                onTap:
                    () => _go(
                      RequestTrackingScreen(requestId: d['id'] as String),
                    ),
              );
            }).toList(),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final c = Theme.of(context).colorScheme;
    final name = user?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: dashboardText(context, 'Switch mode', 'موڈ تبدیل کریں'),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/role-select'),
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
        title: Text(dashboardText(context, 'Donor home', 'عطیہ دہندہ ہوم')),
        actions: [
          IconButton(
            tooltip: dashboardText(context, 'Notifications', 'اطلاعات'),
            onPressed: () => _go(const NotificationHistoryScreen()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: dashboardText(context, 'Settings', 'ترتیبات'),
            onPressed: () => _go(const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) _requests();
          if (i == 2) _go(const DonationHistoryScreen());
          if (i == 3) _profile();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: dashboardText(context, 'Home', 'ہوم'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bloodtype_outlined),
            label: dashboardText(context, 'Requests', 'درخواستیں'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: dashboardText(context, 'History', 'تاریخ'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: dashboardText(context, 'Profile', 'پروفائل'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: dashboardInsets(context),
            children: [
              DashboardPanel(
                tint: c.primaryContainer.withValues(alpha: .35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        dashboardText(
                          context,
                          'Available to donate',
                          'عطیہ دینے کے لیے دستیاب',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        dashboardText(
                          context,
                          'Let nearby receivers know you can help.',
                          'قریبی ضرورت مندوں کو اپنی دستیابی بتائیں۔',
                        ),
                      ),
                      value: user?.isAvailable ?? false,
                      onChanged: _saving || user == null ? null : _availability,
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          child: Text(
                            user?.bloodGroup ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dashboardText(
                                  context,
                                  'Hello, $name',
                                  'سلام، $name',
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                dashboardText(
                                  context,
                                  'Your next act of kindness starts here.',
                                  'آپ کی مدد کا اگلا قدم یہیں سے شروع ہوتا ہے۔',
                                ),
                                style: TextStyle(color: c.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DashboardHeading(
                dashboardText(context, 'Your next step', 'آپ کا اگلا قدم'),
                action: dashboardText(context, 'View all', 'سب دیکھیں'),
                onTap: () => _requests(3),
              ),
              StreamBuilder<Map<String, dynamic>>(
                stream: _active,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return DashboardPanel(
                      child: Text(AppFeedback.message(snap.error!)),
                    );
                  }
                  if (!snap.hasData) return const PremiumLoading(rows: 1);
                  if ((snap.data!['items'] as List).isEmpty) {
                    return DashboardAction(
                      title: dashboardText(
                        context,
                        'Ready for your next donation?',
                        'اگلے عطیے کے لیے تیار ہیں؟',
                      ),
                      subtitle: dashboardText(
                        context,
                        'Review a request and confirm when you can help.',
                        'درخواست دیکھیں اور دستیابی کی تصدیق کریں۔',
                      ),
                      icon: Icons.volunteer_activism_outlined,
                      onTap: () => _requests(),
                    );
                  }
                  return Column(
                    children:
                        (snap.data!['items'] as List)
                            .take(3)
                            .map(
                              (doc) => OpportunityCard(
                                data: Map<String, dynamic>.from(doc),
                                action: dashboardText(
                                  context,
                                  'Continue active donation',
                                  'جاری عطیہ دیکھیں',
                                ),
                                onTap:
                                    () => _go(
                                      RequestTrackingScreen(
                                        requestId: doc['id'] as String,
                                      ),
                                    ),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
              DashboardHeading(
                dashboardText(
                  context,
                  'Direct invitations',
                  'براہ راست دعوتیں',
                ),
                action: dashboardText(context, 'View all', 'سب دیکھیں'),
                onTap: () => _requests(1),
              ),
              _preview(_invitations, invitations: true),
              DashboardHeading(
                dashboardText(
                  context,
                  'Blood needed nearby',
                  'قریب خون کی ضرورت',
                ),
                action: dashboardText(context, 'Explore', 'تلاش کریں'),
                onTap: () => _requests(),
              ),
              _preview(_nearby, invitations: false),
              if (user?.role == 'donor')
                DonorAwareness(
                  key: ValueKey(_refreshKey),
                  onAction: (action) {
                    if (action == 'profile') {
                      _profile();
                    } else if (action == 'history') {
                      _go(const DonationHistoryScreen());
                    } else {
                      _requests();
                    }
                  },
                ),

              DashboardHeading(
                dashboardText(context, 'Your contribution', 'آپ کی مدد'),
              ),
              DashboardPanel(
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    FutureBuilder<int?>(
                      future: _donations,
                      builder:
                          (context, snap) => _stat(
                            dashboardText(context, 'Donations', 'عطیات'),
                            snap.connectionState != ConnectionState.done
                                ? '...'
                                : '${snap.data ?? '-'}',
                            Icons.bloodtype_outlined,
                          ),
                    ),
                    _stat(
                      dashboardText(context, 'Points', 'پوائنٹس'),
                      '${user?.rewardPoints ?? 0}',
                      Icons.stars_outlined,
                    ),
                    TextButton(
                      onPressed: () => _go(const RewardsScreen()),
                      child: Text(
                        dashboardText(
                          context,
                          'Rewards & certificates',
                          'انعامات اور اسناد',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _go(const EligibilityStatusScreen()),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(
                  dashboardText(
                    context,
                    'Recorded eligibility & next date',
                    'ریکارڈ شدہ اہلیت اور اگلی تاریخ',
                  ),
                ),
              ),
              Text(
                dashboardText(
                  context,
                  'Donation eligibility is confirmed by healthcare staff before donation.',
                  'عطیہ دینے سے پہلے طبی عملہ اہلیت کی تصدیق کرتا ہے۔',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label),
        ],
      ),
    ],
  );
}
