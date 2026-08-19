import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_web_users.dart';
import 'admin_web_requests.dart';
import 'admin_web_analytics.dart';
import 'admin_web_donations.dart';
import 'admin_web_reports.dart';
import '../../auth/login_screen.dart';

/// ── Admin Console design tokens ────────────────────────────────────────
/// Kept local to this file rather than folded into the global AppColors,
/// so the donor/receiver-facing app (warm crimson-on-white) is untouched.
/// The admin console gets its own quieter "control room" identity: a
/// charcoal-navy sidebar, one refined red reserved for the brand mark and
/// alerts only, and a cool grey canvas built for scanning numbers and
/// tables rather than for persuasion.
class _T {
  static const ink = Color(0xFF12141C); // sidebar background
  static const inkPanel = Color(0xFF1B1E29); // active/hover nav row
  static const inkBorder = Color(0xFF262A38);
  static const crimson = Color(0xFFD8324B); // brand accent, alerts only
  static const crimsonDeep = Color(0xFFA31E33);
  static const canvas = Color(0xFFF5F6FA); // page background
  static const hairline = Color(0xFFE7E9F0);
  static const ink900 = Color(0xFF14161F); // primary text on canvas
  static const slate500 = Color(0xFF6B7280); // secondary text
  static const slate400 = Color(0xFF9CA3AF);
  static const emerald = Color(0xFF149A5B);
  static const amber = Color(0xFFC9820A);
  static const azure = Color(0xFF3457D5);

  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink900,
        height: 1.2,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink900,
        height: 1.45,
      );
}

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({Key? key}) : super(key: key);

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  static const _sections = [
    ('Dashboard', Icons.space_dashboard_rounded),
    ('Users', Icons.people_alt_rounded),
    ('Blood Requests', Icons.bloodtype_rounded),
    ('Analytics', Icons.insights_rounded),
    ('Donations', Icons.favorite_rounded),
    ('Reports', Icons.flag_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const _DashboardHome(),
      AdminWebUsers(),
      AdminWebRequests(),
      AdminWebAnalytics(),
      AdminWebDonations(),
      AdminWebReports(),
    ];
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _T.canvas,
      body: isWide
          ? Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            sections: _sections,
            onTap: (i) => setState(() => _selectedIndex = i),
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _sections[_selectedIndex].$1),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      )
          : Column(
        children: [
          _TopBar(
            title: _sections[_selectedIndex].$1,
            compact: true,
            onLogout: _logout,
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
        decoration: BoxDecoration(
          color: _T.ink,
          border: Border(top: BorderSide(color: _T.inkBorder)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: _T.crimson,
            unselectedItemColor: _T.slate400,
            selectedLabelStyle: _T.body(size: 11, weight: FontWeight.w700),
            unselectedLabelStyle: _T.body(size: 11, weight: FontWeight.w500),
            type: BottomNavigationBarType.fixed,
            items: _sections
                .map((s) => BottomNavigationBarItem(
              icon: Icon(s.$2),
              label: s.$1 == 'Blood Requests' ? 'Requests' : s.$1,
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<(String, IconData)> sections;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'admin';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Container(
      width: 248,
      color: _T.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand mark ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_T.crimson, _T.crimsonDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'BC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Connect',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'ADMIN CONSOLE',
                        style: GoogleFonts.inter(
                          color: _T.slate400,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: _T.inkBorder, height: 1),
          const SizedBox(height: 12),

          // ── Nav items ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'MENU',
              style: GoogleFonts.inter(
                color: _T.slate400,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),

          ...List.generate(sections.length, (i) {
            final selected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Material(
                color: selected ? _T.inkPanel : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: _T.inkPanel.withOpacity(0.6),
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        // left accent bar for the active section
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: selected ? _T.crimson : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Icon(
                          sections[i].$2,
                          size: 19,
                          color: selected ? Colors.white : _T.slate400,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sections[i].$1,
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : _T.slate400,
                            fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),
          Divider(color: _T.inkBorder, height: 1),

          // ── Account footer ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _T.crimson.withOpacity(0.18),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: _T.crimson,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: _T.slate400),
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final bool compact;
  final VoidCallback? onLogout;

  const _TopBar({required this.title, this.compact = false, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _T.hairline)),
      ),
      child: Row(
        children: [
          if (compact) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_T.crimson, _T.crimsonDeep]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('BC',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Admin Console',
                    style: GoogleFonts.inter(
                        color: _T.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6)),
                Text(title, style: _T.display(size: 18)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _T.emerald.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: _T.emerald, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Live data',
                    style: GoogleFonts.inter(
                        color: _T.emerald,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (compact) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded, color: _T.slate500),
              onPressed: onLogout,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section header helper ────────────────────────────────────────────
Widget _sectionHeader(String eyebrow, String title, {bool live = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow,
                  style: GoogleFonts.inter(
                      color: _T.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(title, style: _T.display(size: 17)),
            ],
          ),
        ),
        if (live)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _T.emerald, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Live',
                  style: GoogleFonts.inter(
                      color: _T.emerald,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
      ],
    ),
  );
}

// ─── Status pill helper ────────────────────────────────────────────────
Widget _statusPill(String status, {Map<String, Color>? overrides}) {
  final palette = <String, Color>{
    'pending': _T.amber,
    'approved': _T.emerald,
    'fulfilled': _T.emerald,
    'rejected': _T.crimson,
    ...?overrides,
  };
  final color = palette[status] ?? _T.slate500;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(status,
            style: GoogleFonts.inter(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ─── Dashboard Home ─────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  const _DashboardHome({Key? key}) : super(key: key);

  Future<Map<String, int>> _fetchStats() async {
    final db = FirebaseFirestore.instance;

    final users = await db.collection('users').get();
    final requests = await db.collection('blood_requests').get();
    final donations = await db.collection('donations').get();

    final pendingUsers = await db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .get();

    return {
      'users': users.size,
      'requests': requests.size,
      'donations': donations.size,
      'pendingUsers': pendingUsers.size,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('OVERVIEW', 'At a glance'),

          FutureBuilder<Map<String, int>>(
            future: _fetchStats(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: CircularProgressIndicator(color: _T.crimson)),
                );
              }
              final data = snap.data ??
                  {
                    'users': 0,
                    'requests': 0,
                    'donations': 0,
                    'pendingUsers': 0,
                  };

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Total Users',
                    value: '${data['users']}',
                    icon: Icons.people_alt_rounded,
                    color: _T.azure,
                  ),
                  _StatCard(
                    label: 'Blood Requests',
                    value: '${data['requests']}',
                    icon: Icons.bloodtype_rounded,
                    color: _T.crimson,
                  ),
                  _StatCard(
                    label: 'Donations',
                    value: '${data['donations']}',
                    icon: Icons.favorite_rounded,
                    color: _T.emerald,
                  ),
                  _StatCard(
                    label: 'Pending Approvals',
                    value: '${data['pendingUsers']}',
                    icon: Icons.person_add_alt_1_rounded,
                    color: _T.amber,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 36),
          _sectionHeader('ACTIVITY', 'Recent blood requests', live: true),

          _ListPanel(
            stream: FirebaseFirestore.instance
                .collection('blood_requests')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            emptyText: 'No blood requests yet.',
            rowBuilder: (doc) {
              final d = doc.data() as Map<String, dynamic>;
              final status = d['status'] ?? 'pending';
              return _PanelRow(
                leadingText: d['bloodGroup'] ?? '?',
                leadingColor: _T.crimson,
                title: d['patientName'] ?? 'Unknown',
                subtitle: d['hospital'] ?? '',
                trailing: _statusPill(status),
              );
            },
          ),

          const SizedBox(height: 36),
          _sectionHeader('DIRECTORY', 'Recent users', live: true),

          _ListPanel(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            emptyText: 'No users yet.',
            rowBuilder: (doc) {
              final d = doc.data() as Map<String, dynamic>;
              final status = d['status'] ?? 'pending';
              final name = (d['name'] ?? 'U').toString();
              return _PanelRow(
                leadingText: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                leadingColor: _T.azure,
                title: d['name'] ?? 'Unknown',
                subtitle: d['email'] ?? '',
                trailing: _statusPill(status),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 16),
          Text(value, style: _T.display(size: 26)),
          const SizedBox(height: 3),
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  color: _T.slate500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

// ─── Reusable list panel (white card + hairline rows, real-time) ───────
class _ListPanel extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyText;
  final _PanelRow Function(QueryDocumentSnapshot doc) rowBuilder;

  const _ListPanel({
    required this.stream,
    required this.emptyText,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.hairline),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: CircularProgressIndicator(color: _T.crimson)),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyText, style: _T.body(color: _T.slate500)),
            );
          }
          return Column(
            children: List.generate(docs.length, (i) {
              final row = rowBuilder(docs[i]);
              return Column(
                children: [
                  row,
                  if (i != docs.length - 1)
                    Divider(height: 1, color: _T.hairline),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  final String leadingText;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PanelRow({
    required this.leadingText,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: leadingColor.withOpacity(0.1),
            child: Text(
              leadingText,
              style: TextStyle(
                  color: leadingColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _T.body(size: 14, weight: FontWeight.w600)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: _T.body(size: 12.5, color: _T.slate500)),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}