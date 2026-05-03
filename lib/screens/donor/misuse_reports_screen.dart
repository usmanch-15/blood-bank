import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/misuse_report_model.dart';

/// Admin Misuse Reports Screen — view, investigate, and resolve reports
class MisuseReportsScreen extends StatefulWidget {
  const MisuseReportsScreen({super.key});

  @override
  State<MisuseReportsScreen> createState() => _MisuseReportsScreenState();
}

class _MisuseReportsScreenState extends State<MisuseReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // 🔧 Dummy data — replace with Firestore query in production
  final List<MisuseReportModel> _reports = [
    MisuseReportModel(
      id: 'r001',
      reporterId: 'u101',
      reportedUserId: 'u202',
      reportType: 'fake_profile',
      title: 'Fake Donor Profile',
      description:
      'This user claims to be a donor but never responds to requests. '
          'Profile picture looks stock. Phone number is invalid.',
      reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'pending',
    ),
    MisuseReportModel(
      id: 'r002',
      reporterId: 'u103',
      reportedUserId: 'u205',
      reportType: 'fraud',
      title: 'Requesting Blood for Money',
      description:
      'This user sent a blood request and then privately asked me to '
          'pay for the donation. This is against platform rules.',
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'investigating',
      adminNotes: 'Contacted reported user for response. Awaiting reply.',
      adminReviewedBy: 'Admin Najeeb',
    ),
    MisuseReportModel(
      id: 'r003',
      reporterId: 'u110',
      reportedUserId: 'u211',
      reportType: 'misuse',
      title: 'Repeated False SOS Alerts',
      description:
      'This user has sent 4 SOS alerts in 2 days, none of which were '
          'genuine emergencies. Donors wasted time and travel.',
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'resolved',
      adminNotes: 'User warned. Account restricted from SOS for 30 days.',
      adminReviewedBy: 'Admin Najeeb',
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MisuseReportModel(
      id: 'r004',
      reporterId: 'u115',
      reportedUserId: null,
      reportType: 'other',
      title: 'App Bug Causing Double Requests',
      description:
      'When I submit a blood request, it gets submitted twice. I have '
          'to manually cancel the duplicate. This might be a technical issue.',
      reportedAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'dismissed',
      adminNotes: 'Forwarded to development team. Not a misuse case.',
      adminReviewedBy: 'Admin Najeeb',
      resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MisuseReportModel(
      id: 'r005',
      reporterId: 'u120',
      reportedUserId: 'u230',
      reportType: 'fake_profile',
      title: 'Unverified Medical Claims',
      description:
      'User claims to be a certified doctor recommending blood types '
          'in comments, but has no credentials on profile.',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      status: 'pending',
    ),
  ];

  final Map<String, String> _reportTypeLabels = {
    'fraud': 'Fraud',
    'misuse': 'Misuse',
    'fake_profile': 'Fake Profile',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MisuseReportModel> _filterReports(String status) {
    return _reports.where((r) {
      final matchesStatus = r.status == status;
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reportType.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _updateStatus(String id, String newStatus, {String? notes}) {
    setState(() {
      final idx = _reports.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final updated = _reports[idx].copyWith(
          status: newStatus,
          adminNotes: notes ?? _reports[idx].adminNotes,
          adminReviewedBy: 'Admin Najeeb',
          resolvedAt:
          (newStatus == 'resolved' || newStatus == 'dismissed')
              ? DateTime.now()
              : null,
        );
        _reports[idx] = updated;
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'investigating':
        return AppColors.secondaryBlue;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'investigating':
        return Icons.manage_search;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'dismissed':
        return Icons.remove_circle_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'fraud':
        return AppColors.error;
      case 'misuse':
        return AppColors.warning;
      case 'fake_profile':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.textSecondary;
    }
  }

  int _countByStatus(String status) =>
      _reports.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final pendingCount = _countByStatus('pending');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Misuse Reports',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: [
            Tab(text: 'Pending ($pendingCount)'),
            Tab(text: 'Investigating (${_countByStatus('investigating')})'),
            Tab(text: 'Resolved (${_countByStatus('resolved')})'),
            Tab(text: 'Dismissed (${_countByStatus('dismissed')})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.error.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_reports.length} total reports · $pendingCount need action',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by title or type...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportList('pending'),
                _buildReportList('investigating'),
                _buildReportList('resolved'),
                _buildReportList('dismissed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Report list per tab
  // ─────────────────────────────────────────────
  Widget _buildReportList(String status) {
    final reports = _filterReports(status);

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(status), size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'No $status reports',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (context, i) => _buildReportCard(reports[i]),
    );
  }

  // ─────────────────────────────────────────────
  // Report card
  // ─────────────────────────────────────────────
  Widget _buildReportCard(MisuseReportModel report) {
    final typeColor = _typeColor(report.reportType);
    final statusColor = _statusColor(report.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.12),
                  child:
                  Icon(Icons.flag_outlined, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _reportTypeLabels[report.reportType] ?? 'Other',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: typeColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(_statusIcon(report.status),
                              size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            report.status[0].toUpperCase() +
                                report.status.substring(1),
                            style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              report.description,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Meta info
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report.reportedAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (report.reportedUserId != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.person_outline,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'User ID: ${report.reportedUserId}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),

            // Admin notes
            if (report.adminNotes != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${report.adminReviewedBy}: ${report.adminNotes}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (report.status == 'pending' ||
                report.status == 'investigating') ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildActionButtons(report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(MisuseReportModel report) {
    if (report.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showNotesDialog(
                report,
                'Dismiss Report',
                'dismissed',
                Icons.remove_circle_outline,
                Colors.grey,
              ),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Dismiss'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side:
                const BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showNotesDialog(
                report,
                'Start Investigation',
                'investigating',
                Icons.manage_search,
                AppColors.secondaryBlue,
              ),
              icon: const Icon(Icons.manage_search, size: 16),
              label: const Text('Investigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }

    // Investigating state
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showNotesDialog(
              report,
              'Dismiss Report',
              'dismissed',
              Icons.remove_circle_outline,
              Colors.grey,
            ),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Dismiss'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showNotesDialog(
              report,
              'Mark as Resolved',
              'resolved',
              Icons.check_circle_outline,
              AppColors.success,
            ),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Resolve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotesDialog(
      MisuseReportModel report,
      String actionTitle,
      String newStatus,
      IconData icon,
      Color color,
      ) {
    final notesController =
    TextEditingController(text: report.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(actionTitle,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add admin notes (optional):',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notes...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(report.id, newStatus,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report marked as $newStatus.'),
                  backgroundColor: color,
                ),
              );
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
