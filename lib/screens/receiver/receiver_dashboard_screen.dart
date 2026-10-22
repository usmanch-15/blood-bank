import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/paged_records.dart';
import '../requests/request_tracking_screen.dart';
import '../requests/request_list_screen.dart';
import '../notification/notification_history_screen.dart';
import '../settings/settings_screen.dart';
import '../maps/nearby_donors_map_screen.dart';
import 'blood_request_form_screen.dart';
import 'sos_emergency_screen.dart';

class ReceiverDashboardScreen extends StatefulWidget {
  const ReceiverDashboardScreen({super.key});
  @override
  State<ReceiverDashboardScreen> createState() =>
      _ReceiverDashboardScreenState();
}

class _ReceiverDashboardScreenState extends State<ReceiverDashboardScreen> {
  int _refresh = 0;
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().currentUser?.name ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: dashboardText(context, 'Switch mode', 'موڈ تبدیل کریں'),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/role-select'),
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
        title: Text(dashboardText(context, 'Receiver home', 'وصول کنندہ ہوم')),
        actions: [
          IconButton(
            tooltip: dashboardText(context, 'Notifications', 'اطلاعات'),
            onPressed: () => _open(const NotificationHistoryScreen()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: dashboardText(context, 'Settings', 'ترتیبات'),
            onPressed: () => _open(const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) _open(const RequestListScreen());
          if (i == 2) _open(const NearbyDonorsMapScreen());
          if (i == 3) _open(const SettingsScreen());
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: dashboardText(context, 'Home', 'ہوم'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            label: dashboardText(context, 'Requests', 'درخواستیں'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            label: dashboardText(context, 'Donors', 'عطیہ دہندگان'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: dashboardText(context, 'Settings', 'ترتیبات'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _refresh++),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              DashboardPanel(
                tint: c.primaryContainer.withValues(alpha: .35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite_outline_rounded, color: c.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dashboardText(
                              context,
                              'HERE TO HELP',
                              'مدد کے لیے حاضر',
                            ),
                            style: TextStyle(
                              color: c.primary,
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      dashboardText(context, 'Hello, $name', 'سلام، $name'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dashboardText(
                        context,
                        'Connect with donors. Keep every request in one place.',
                        'عطیہ دہندگان سے رابطہ کریں اور اپنی درخواستیں ایک جگہ دیکھیں۔',
                      ),
                      style: TextStyle(color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _open(const BloodRequestFormScreen()),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          dashboardText(
                            context,
                            'Create blood request',
                            'خون کی درخواست بنائیں',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DashboardPanel(
                tint: c.errorContainer.withValues(alpha: .25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emergency_outlined, color: c.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dashboardText(
                              context,
                              'Need help urgently?',
                              'فوری مدد درکار ہے؟',
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dashboardText(
                        context,
                        'Send an SOS to nearby donors and follow their responses.',
                        'قریبی عطیہ دہندگان کو فوری اطلاع بھیجیں اور جوابات دیکھیں۔',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _open(const SosEmergencyScreen()),
                          icon: const Icon(Icons.sos),
                          label: Text(
                            dashboardText(
                              context,
                              'Start SOS',
                              'ایس او ایس شروع کریں',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => _open(const RequestListScreen(mode: 'sos')),
                          child: Text(
                            dashboardText(
                              context,
                              'SOS status & history',
                              'ایس او ایس کی صورتحال',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DashboardAction(
                title: dashboardText(
                  context,
                  'Find nearby donors',
                  'قریبی عطیہ دہندگان',
                ),
                subtitle: dashboardText(
                  context,
                  'Explore compatible donors on the map.',
                  'نقشے پر موزوں عطیہ دہندگان تلاش کریں۔',
                ),
                icon: Icons.travel_explore_rounded,
                onTap: () => _open(const NearbyDonorsMapScreen()),
              ),
              DashboardHeading(
                dashboardText(context, 'Your requests', 'آپ کی درخواستیں'),
                action: dashboardText(context, 'View all', 'سب دیکھیں'),
                onTap: () => _open(const RequestListScreen()),
              ),
              if (uid != null)
                PagedRecords(
                  key: ValueKey(_refresh),
                  shrinkWrap: true,
                  query: FirebaseFirestore.instance
                      .collection('blood_requests')
                      .where('requesterId', isEqualTo: uid)
                      .orderBy('createdAt', descending: true),
                  emptyMessage: dashboardText(
                    context,
                    'No requests yet. Create a request to start finding donors.',
                    'ابھی کوئی درخواست نہیں۔ عطیہ دہندگان تلاش کرنے کے لیے درخواست بنائیں۔',
                  ),
                  itemBuilder:
                      (context, doc) => OpportunityCard(
                        data: doc.data(),
                        action: dashboardText(
                          context,
                          'Track request & donors',
                          'درخواست اور عطیہ دہندگان دیکھیں',
                        ),
                        onTap:
                            () =>
                                _open(RequestTrackingScreen(requestId: doc.id)),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
