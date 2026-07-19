import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';


class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Year'];
  bool _exporting = false;

  // ─── Dummy Analytics Data ───────────────────────────────────────
  final Map<String, Map<String, dynamic>> _periodData = {
    'This Week': {
      'totalDonations': 18,
      'totalRequests': 22,
      'fulfilledRequests': 15,
      'activedonors': 34,
      'newUsers': 7,
      'sosAlerts': 3,
      'bloodGroupData': {
        'O+': 6, 'A+': 5, 'B+': 3, 'AB+': 2, 'O-': 1, 'A-': 1,
      },
      'monthlyDonations': [3, 2, 4, 3, 2, 2, 2],
      'monthLabels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
    'This Month': {
      'totalDonations': 56,
      'totalRequests': 71,
      'fulfilledRequests': 48,
      'activedonors': 80,
      'newUsers': 24,
      'sosAlerts': 9,
      'bloodGroupData': {
        'O+': 18, 'A+': 12, 'B+': 10, 'AB+': 6, 'O-': 5, 'A-': 5,
      },
      'monthlyDonations': [8, 12, 9, 14, 7, 6],
      'monthLabels': ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'],
    },
    'This Year': {
      'totalDonations': 430,
      'totalRequests': 520,
      'fulfilledRequests': 370,
      'activedonors': 210,
      'newUsers': 180,
      'sosAlerts': 64,
      'bloodGroupData': {
        'O+': 130, 'A+': 95, 'B+': 80, 'AB+': 45, 'O-': 40, 'A-': 40,
      },
      'monthlyDonations': [28, 32, 38, 42, 30, 35, 40, 38, 45, 34, 36, 32],
      'monthLabels': [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ],
    },
  };

  Map<String, dynamic> get _current => _periodData[_selectedPeriod]!;

  double get _fulfillmentRate {
    final total = _current['totalRequests'] as int;
    final fulfilled = _current['fulfilledRequests'] as int;
    if (total == 0) return 0;
    return (fulfilled / total) * 100;
  }

  Future<void> _exportAnalytics() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bloodGroupData = _current['bloodGroupData'] as Map<String, int>;

      final rows = <List<dynamic>>[
        ['Blood Bank Analytics — $_selectedPeriod'],
        [],
        ['Metric', 'Value'],
        ['Total Donations', _current['totalDonations']],
        ['Blood Requests', _current['totalRequests']],
        ['Fulfilled Requests', _current['fulfilledRequests']],
        ['Fulfillment Rate (%)', _fulfillmentRate.toStringAsFixed(1)],
        ['Active Donors', _current['activedonors']],
        ['New Users', _current['newUsers']],
        ['SOS Alerts', _current['sosAlerts']],
        [],
        ['Blood Group', 'Count'],
        ...bloodGroupData.entries.map((e) => [e.key, e.value]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final safePeriod = _selectedPeriod.replaceAll(' ', '_');
      final file = File('${dir.path}/blood_bank_analytics_$safePeriod.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Blood Bank Analytics — $_selectedPeriod',
        subject: 'Blood Bank Analytics Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export analytics: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.ios_share_outlined),
            tooltip: 'Export',
            onPressed: _exporting ? null : _exportAnalytics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            _buildPeriodFilter(),
            const SizedBox(height: 20),

            // KPI cards
            _buildKpiSection(),
            const SizedBox(height: 24),

            // Fulfillment rate
            _buildFulfillmentCard(),
            const SizedBox(height: 24),

            // Donation trend (bar chart)
            _buildSectionTitle('Donation Trend'),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 24),

            // Blood group breakdown
            _buildSectionTitle('Blood Group Breakdown'),
            const SizedBox(height: 12),
            _buildBloodGroupChart(),
            const SizedBox(height: 24),

            // Recent activity
            _buildSectionTitle('System Highlights'),
            const SizedBox(height: 12),
            _buildHighlightCards(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Period filter chips
  // ─────────────────────────────────────────────
  Widget _buildPeriodFilter() {
    return Row(
      children: _periods.map((p) {
        final selected = _selectedPeriod == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p),
            selected: selected,
            onSelected: (_) => setState(() => _selectedPeriod = p),
            selectedColor: AppColors.primaryRed,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // KPI stat cards
  // ─────────────────────────────────────────────
  Widget _buildKpiSection() {
    final items = [
      {
        'label': 'Total Donations',
        'value': '${_current['totalDonations']}',
        'icon': Icons.favorite,
        'color': AppColors.primaryRed,
      },
      {
        'label': 'Blood Requests',
        'value': '${_current['totalRequests']}',
        'icon': Icons.local_hospital,
        'color': AppColors.secondaryBlue,
      },
      {
        'label': 'Active Donors',
        'value': '${_current['activedonors']}',
        'icon': Icons.people,
        'color': AppColors.secondaryGreen,
      },
      {
        'label': 'SOS Alerts',
        'value': '${_current['sosAlerts']}',
        'icon': Icons.sos,
        'color': AppColors.error,
      },
      {
        'label': 'New Users',
        'value': '${_current['newUsers']}',
        'icon': Icons.person_add,
        'color': AppColors.warning,
      },
      {
        'label': 'Fulfilled',
        'value': '${_current['fulfilledRequests']}',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = item['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                item['value'] as String,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['label'] as String,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Fulfillment rate card
  // ─────────────────────────────────────────────
  Widget _buildFulfillmentCard() {
    final rate = _fulfillmentRate;
    final color = rate >= 70
        ? AppColors.success
        : rate >= 40
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: color),
              const SizedBox(width: 8),
              const Text(
                'Request Fulfillment Rate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_current['fulfilledRequests']} of ${_current['totalRequests']} requests fulfilled',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Bar chart (custom drawn)
  // ─────────────────────────────────────────────
  Widget _buildBarChart() {
    final data = _current['monthlyDonations'] as List<int>;
    final labels = _current['monthLabels'] as List<String>;
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final heightFrac = maxVal > 0 ? data[i] / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${data[i]}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: heightFrac * 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withOpacity(0.8),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: labels
                .map((l) => Expanded(
              child: Text(
                l,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Blood group breakdown
  // ─────────────────────────────────────────────
  Widget _buildBloodGroupChart() {
    final data = _current['bloodGroupData'] as Map<String, int>;
    final total = data.values.fold(0, (a, b) => a + b);
    final colors = [
      AppColors.primaryRed,
      AppColors.secondaryBlue,
      AppColors.secondaryGreen,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF9C27B0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: List.generate(data.length, (i) {
          final key = data.keys.elementAt(i);
          final val = data.values.elementAt(i);
          final pct = total > 0 ? val / total : 0.0;
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$val',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Highlight cards
  // ─────────────────────────────────────────────
  Widget _buildHighlightCards() {
    final highlights = [
      {
        'icon': Icons.trending_up,
        'color': AppColors.success,
        'title': 'Donation rate is up',
        'sub': 'Compared to last period, donations increased by 14%.',
      },
      {
        'icon': Icons.sos,
        'color': AppColors.error,
        'title': 'SOS alerts responded',
        'sub':
        '${_current['sosAlerts']} SOS alerts were raised. Average response time: 8 min.',
      },
      {
        'icon': Icons.group_add,
        'color': AppColors.secondaryBlue,
        'title': 'New registrations',
        'sub':
        '${_current['newUsers']} new users joined the platform this period.',
      },
    ];

    return Column(
      children: highlights.map((h) {
        final color = h['color'] as Color;
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(h['icon'] as IconData, color: color),
            ),
            title: Text(
              h['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              h['sub'] as String,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}