import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/misuse_report_model.dart';

/// Misuse Reports Handling Screen - Admin function
class MisuseReportsScreen extends StatefulWidget {
  const MisuseReportsScreen({super.key});

  @override
  State<MisuseReportsScreen> createState() => _MisuseReportsScreenState();
}

class _MisuseReportsScreenState extends State<MisuseReportsScreen> {
  late FirestoreService _firestoreService;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Misuse Reports'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('investigating', 'Investigating'),
                  const SizedBox(width: 8),
                  _buildFilterChip('resolved', 'Resolved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('dismissed', 'Dismissed'),
                ],
              ),
            ),
          ),
          // Reports List
          Expanded(
            child: _filterStatus == 'pending'
                ? StreamBuilder<List<MisuseReportModel>>(
                    stream: _firestoreService.getPendingMisuseReports(),
                    builder: (context, snapshot) {
                      return _buildReportsList(snapshot);
                    },
                  )
                : StreamBuilder<List<MisuseReportModel>>(
                    stream: _firestoreService.getAllMisuseReports(),
                    builder: (context, snapshot) {
                      final reports = (snapshot.data ?? [])
                          .where((r) => r.status == _filterStatus)
                          .toList();
                      return snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : _buildReportsListView(reports);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == value,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primaryRed.withOpacity(0.3),
      labelStyle: TextStyle(
        color: _filterStatus == value ? AppColors.primaryRed : AppColors.textSecondary,
        fontWeight: _filterStatus == value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReportsList(AsyncSnapshot<List<MisuseReportModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    return _buildReportsListView(snapshot.data ?? []);
  }

  Widget _buildReportsListView(List<MisuseReportModel> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('No reports found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(MisuseReportModel report) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
    final statusColor = _getStatusColor(report.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getReportTypeIcon(report.reportType),
            color: statusColor,
          ),
        ),
        title: Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Type: ${report.reportType}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(report.reportedAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(report.description),
                const SizedBox(height: 16),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info, size: 14, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${report.status}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Admin Notes
                if (report.adminNotes != null) ...[
                  const Text(
                    'Admin Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(report.adminNotes!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (report.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _updateReportStatus(report, 'dismissed'),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                          ),
                          onPressed: () =>
                              _updateReportStatus(report, 'investigating'),
                          child: const Text('Investigate',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                else if (report.status == 'investigating')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    onPressed: () =>
                        _showResolveDialog(context, report),
                    child: const Text('Mark as Resolved',
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateReportStatus(MisuseReportModel report, String newStatus) {
    _firestoreService.updateMisuseReport(report.id, {
      'status': newStatus,
      'adminNotes': report.adminNotes,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report updated to $newStatus')),
    );
  }

  void _showResolveDialog(BuildContext context, MisuseReportModel report) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: SingleChildScrollView(
          child: TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add resolution notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            onPressed: () {
              _firestoreService.updateMisuseReport(report.id, {
                'status': 'resolved',
                'adminNotes': notesController.text,
                'resolvedAt': DateTime.now(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report resolved')),
              );
            },
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'investigating':
        return AppColors.secondaryBlue;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.textSecondary;
      default:
        return AppColors.textPrimary;
    }
  }

  IconData _getReportTypeIcon(String type) {
    switch (type) {
      case 'fraud':
        return Icons.warning;
      case 'misuse':
        return Icons.block;
      case 'fake_profile':
        return Icons.person_off;
      default:
        return Icons.report;
    }
  }
}
