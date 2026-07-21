import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';

class AdminWebAnalytics extends StatefulWidget {
  const AdminWebAnalytics({Key? key}) : super(key: key);

  @override
  State<AdminWebAnalytics> createState() => _AdminWebAnalyticsState();
}

class _AdminWebAnalyticsState extends State<AdminWebAnalytics> {
  bool _isLoading = true;
  String _error = '';

  // Live stats from Firestore
  int _totalUsers = 0;
  int _totalDonors = 0;
  int _totalReceivers = 0;
  int _totalDonations = 0;
  int _totalRequests = 0;
  int _pendingRequests = 0;
  int _fulfilledRequests = 0;
  int _pendingUsers = 0;
  int _totalPoints = 0;

  // Blood group breakdown
  Map<String, int> _bloodGroupDonations = {};
  Map<String, int> _bloodGroupRequests = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final db = FirebaseFirestore.instance;

      // Parallel fetches
      final results = await Future.wait([
        db.collection('users').get(),
        db.collection('donations').get(),
        db.collection('blood_requests').get(),
      ]);

      final usersSnap = results[0];
      final donationsSnap = results[1];
      final requestsSnap = results[2];

      // Users breakdown
      int donors = 0, receivers = 0, pending = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isDonor'] == true) donors++;
        if (data['isReceiver'] == true) receivers++;
        if (data['status'] == 'pending') pending++;
      }

      // Donations breakdown by blood group
      final bgDonations = <String, int>{};
      int totalPts = 0;
      for (final doc in donationsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bg = data['bloodGroup'] as String? ?? 'Unknown';
        bgDonations[bg] = (bgDonations[bg] ?? 0) + 1;
        totalPts += (data['pointsEarned'] as int? ?? 0);
      }

      // Requests breakdown
      int pendingReq = 0, fulfilledReq = 0;
      final bgRequests = <String, int>{};
      for (final doc in requestsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        if (status == 'pending') pendingReq++;
        if (status == 'fulfilled') fulfilledReq++;
        final bg = data['bloodGroup'] as String? ?? 'Unknown';
        bgRequests[bg] = (bgRequests[bg] ?? 0) + 1;
      }

      setState(() {
        _totalUsers = usersSnap.size;
        _totalDonors = donors;
        _totalReceivers = receivers;
        _pendingUsers = pending;
        _totalDonations = donationsSnap.size;
        _totalRequests = requestsSnap.size;
        _pendingRequests = pendingReq;
        _fulfilledRequests = fulfilledReq;
        _totalPoints = totalPts;
        _bloodGroupDonations = bgDonations;
        _bloodGroupRequests = bgRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Error: $_error',
                style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live data from Firestore',
                    style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── KPI Cards Row ─────────────────────────────────────
          _buildKpiRow(),

          const SizedBox(height: 24),

          // ── Two column layout ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood donations by group
              Expanded(
                child: _buildCard(
                  title: 'Donations by Blood Group',
                  icon: Icons.favorite,
                  iconColor: Colors.red,
                  child: _buildBloodGroupChart(_bloodGroupDonations,
                      Colors.red.shade400),
                ),
              ),
              const SizedBox(width: 20),
              // Requests by group
              Expanded(
                child: _buildCard(
                  title: 'Requests by Blood Group',
                  icon: Icons.bloodtype,
                  iconColor: Colors.blue,
                  child: _buildBloodGroupChart(
                      _bloodGroupRequests, Colors.blue.shade400),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Bottom row ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fulfillment rate
              Expanded(
                child: _buildCard(
                  title: 'Request Fulfillment',
                  icon: Icons.donut_large,
                  iconColor: Colors.green,
                  child: _buildFulfillmentWidget(),
                ),
              ),
              const SizedBox(width: 20),
              // User breakdown
              Expanded(
                child: _buildCard(
                  title: 'User Breakdown',
                  icon: Icons.people,
                  iconColor: Colors.purple,
                  child: _buildUserBreakdown(),
                ),
              ),
              const SizedBox(width: 20),
              // Points overview
              Expanded(
                child: _buildCard(
                  title: 'Rewards Overview',
                  icon: Icons.stars,
                  iconColor: Colors.amber,
                  child: _buildRewardsWidget(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── KPI stat cards ──────────────────────────────────────────
  Widget _buildKpiRow() {
    final fulfillmentRate = _totalRequests > 0
        ? (_fulfilledRequests / _totalRequests * 100).toStringAsFixed(1)
        : '0';

    final kpis = [
      {
        'label': 'Total Users',
        'value': '$_totalUsers',
        'sub': '$_pendingUsers pending approval',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'label': 'Total Donations',
        'value': '$_totalDonations',
        'sub': '$_totalDonors active donors',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'label': 'Blood Requests',
        'value': '$_totalRequests',
        'sub': '$_pendingRequests pending',
        'icon': Icons.bloodtype,
        'color': Colors.orange,
      },
      {
        'label': 'Fulfillment Rate',
        'value': '$fulfillmentRate%',
        'sub': '$_fulfilledRequests fulfilled',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    return Row(
      children: kpis.map((k) {
        final color = k['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(k['icon'] as IconData, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k['value'] as String,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        k['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        k['sub'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Blood group horizontal bar chart ────────────────────────
  Widget _buildBloodGroupChart(Map<String, int> data, Color barColor) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No data yet',
              style: TextStyle(color: Colors.grey.shade400)),
        ),
      );
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Column(
      children: sorted.take(8).map((e) {
        final pct = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade100,
                    color: barColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 28,
                child: Text(
                  '${e.value}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Fulfillment rate visual ──────────────────────────────────
  Widget _buildFulfillmentWidget() {
    final rate = _totalRequests > 0
        ? _fulfilledRequests / _totalRequests
        : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: rate,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade100,
                color: Colors.green.shade400,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(rate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text('fulfilled',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendItem('Fulfilled', _fulfilledRequests, Colors.green),
            _legendItem('Pending', _pendingRequests, Colors.orange),
            _legendItem(
                'Other',
                _totalRequests - _fulfilledRequests - _pendingRequests,
                Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label,
            style:
            TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  // ── User breakdown ───────────────────────────────────────────
  Widget _buildUserBreakdown() {
    final items = [
      {'label': 'Donors', 'count': _totalDonors, 'color': Colors.red},
      {
        'label': 'Receivers',
        'count': _totalReceivers,
        'color': Colors.blue
      },
      {
        'label': 'Pending',
        'count': _pendingUsers,
        'color': Colors.orange
      },
    ];

    return Column(
      children: items.map((item) {
        final color = item['color'] as Color;
        final count = item['count'] as int;
        final pct = _totalUsers > 0 ? count / _totalUsers : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label'] as String,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$count',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Rewards overview ─────────────────────────────────────────
  Widget _buildRewardsWidget() {
    final avgPoints =
    _totalDonors > 0 ? (_totalPoints / _totalDonors).toStringAsFixed(0) : '0';
    return Column(
      children: [
        _rewardStat('Total Points Distributed', '$_totalPoints',
            Icons.stars, Colors.amber),
        const SizedBox(height: 12),
        _rewardStat(
            'Avg Points per Donor', avgPoints, Icons.person, Colors.blue),
        const SizedBox(height: 12),
        _rewardStat('Total Donors', '$_totalDonors', Icons.favorite,
            Colors.red),
      ],
    );
  }

  Widget _rewardStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color)),
        ],
      ),
    );
  }
}