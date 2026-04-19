import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';

/// Analytics Dashboard Screen - Admin function
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Statistics
              const Text(
                'Key Metrics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatisticsCards(),
              const SizedBox(height: 32),

              // Demand vs Supply
              const Text(
                'Blood Group Demand',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildBloodGroupDemand(),
              const SizedBox(height: 32),

              // Recent Activity
              const Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSystemOverview(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build statistics cards
  Widget _buildStatisticsCards() {
    return FutureBuilder(
      future: _firestoreService.getDonationStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Donations',
                    value: stats['totalDonations']?.toString() ?? '0',
                    icon: Icons.bloodtype,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Requests',
                    value: stats['totalRequests']?.toString() ?? '0',
                    icon: Icons.medical_services,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Fulfillment Rate',
                    value: '${stats['fulfillmentRate'] ?? 0}%',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Success Rate',
                    value: '87%',
                    icon: Icons.check_circle,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build individual statistic card
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build blood group demand chart
  Widget _buildBloodGroupDemand() {
    return FutureBuilder<Map<String, int>>(
      future: _firestoreService.getBloodGroupDemand(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final demand = snapshot.data ?? {};

        if (demand.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No blood group demand data available',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          );
        }

        final maxDemand =
            demand.values.isEmpty ? 1 : demand.values.reduce((a, b) => a > b ? a : b).toDouble();

        return Column(
          children: demand.entries.map((entry) {
            final percentage = (entry.value / maxDemand * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value} units ($percentage%)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: entry.value / maxDemand,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Build system overview
  Widget _buildSystemOverview() {
    return Column(
      children: [
        _buildOverviewItem(
          icon: Icons.person,
          title: 'Active Donors',
          subtitle: 'Donors registered and active',
          value: '245',
        ),
        const SizedBox(height: 12),
        _buildOverviewItem(
          icon: Icons.person_outline,
          title: 'Active Receivers',
          subtitle: 'Receivers using the platform',
          value: '87',
        ),
        const SizedBox(height: 12),
        _buildOverviewItem(
          icon: Icons.location_on,
          title: 'Campaigns',
          subtitle: 'Active blood donation drives',
          value: '12',
        ),
        const SizedBox(height: 12),
        _buildOverviewItem(
          icon: Icons.report,
          title: 'Pending Reports',
          subtitle: 'Misuse reports under review',
          value: '3',
        ),
      ],
    );
  }

  /// Build individual overview item
  Widget _buildOverviewItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}
