import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/misuse_report_model.dart';
import '../../../constants/app_colors.dart';

class AdminWebReports extends StatefulWidget {
  const AdminWebReports({Key? key}) : super(key: key);

  @override
  State<AdminWebReports> createState() => _AdminWebReportsState();
}

class _AdminWebReportsState extends State<AdminWebReports>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'All';

  final List<String> _types = [
    'All', 'fraud', 'misuse', 'fake_profile', 'other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(
            () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<MisuseReportModel>> _getReports(String status) {
    Query query = FirebaseFirestore.instance
        .collection('misuse_reports')
        .orderBy('reportedAt', descending: true);
    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) => MisuseReportModel.fromFirestore(
        d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Misuse Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and manage user-submitted reports',
                    style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              _buildPendingBadge(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Search + filter ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 12),
              _dropdownFilter(
                value: _typeFilter,
                items: _types,
                onChanged: (v) => setState(() => _typeFilter = v!),
                hint: 'Report Type',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Tabs ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.red.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Investigating'),
                Tab(text: 'Resolved'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportList('all'),
              _buildReportList('pending'),
              _buildReportList('investigating'),
              _buildReportList('resolved'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBadge() {
    return StreamBuilder<List<MisuseReportModel>>(
      stream: _getReports('pending'),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count Unreviewed Report${count == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportList(String status) {
    return StreamBuilder<List<MisuseReportModel>>(
      stream: _getReports(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
              CircularProgressIndicator(color: AppColors.primaryRed));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade400)));
        }

        var reports = snapshot.data ?? [];

        // Search
        if (_searchQuery.isNotEmpty) {
          reports = reports
              .where((r) =>
          r.title.toLowerCase().contains(_searchQuery) ||
              r.description.toLowerCase().contains(_searchQuery))
              .toList();
        }

        // Type filter
        if (_typeFilter != 'All') {
          reports =
              reports.where((r) => r.reportType == _typeFilter).toList();
        }

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report_gmailerrorred_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No reports match your search'
                      : 'No ${status == "all" ? "" : "$status "}reports',
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildReportCard(reports[i]),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(MisuseReportModel report) {
    final statusColor = _statusColor(report.status);
    final typeColor = _typeColor(report.reportType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding:
        const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
          Icon(_typeIcon(report.reportType), color: typeColor, size: 20),
        ),
        title: Text(
          report.title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            _statusChip(report.status, statusColor),
            const SizedBox(width: 8),
            _typeChip(report.reportType, typeColor),
            const SizedBox(width: 8),
            Text(
              _formatDate(report.reportedAt),
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        children: [
          // Description
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              report.description,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
          ),

          if (report.adminNotes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Note: ${report.adminNotes}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (report.status == 'pending') ...[
                _actionBtn(
                  label: 'Investigate',
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () => _updateReportStatus(
                      report.id, 'investigating', report.title),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  label: 'Dismiss',
                  icon: Icons.close,
                  color: Colors.grey,
                  onTap: () => _updateReportStatus(
                      report.id, 'dismissed', report.title),
                ),
              ] else if (report.status == 'investigating') ...[
                _actionBtn(
                  label: 'Mark Resolved',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  onTap: () => _updateReportStatus(
                      report.id, 'resolved', report.title),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  label: 'Dismiss',
                  icon: Icons.close,
                  color: Colors.grey,
                  onTap: () => _updateReportStatus(
                      report.id, 'dismissed', report.title),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addAdminNote(report),
                icon: const Icon(Icons.note_add, size: 16),
                label: const Text('Add Note',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _typeChip(String type, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Future<void> _updateReportStatus(
      String id, String newStatus, String title) async {
    try {
      await FirebaseFirestore.instance
          .collection('misuse_reports')
          .doc(id)
          .update({
        'status': newStatus,
        if (newStatus == 'resolved')
          'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Report "$title" marked as $newStatus'),
            backgroundColor: newStatus == 'resolved'
                ? Colors.green
                : newStatus == 'investigating'
                ? Colors.blue
                : Colors.grey,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addAdminNote(MisuseReportModel report) {
    final ctrl = TextEditingController(text: report.adminNotes ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Admin Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write your admin note here...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('misuse_reports')
                    .doc(report.id)
                    .update({'adminNotes': ctrl.text.trim()});
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'fraud':
        return Colors.red;
      case 'misuse':
        return Colors.orange;
      case 'fake_profile':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fraud':
        return Icons.warning;
      case 'misuse':
        return Icons.report;
      case 'fake_profile':
        return Icons.person_off;
      default:
        return Icons.flag;
    }
  }

  Widget _searchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search reports...',
          hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
          Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items
              .map((i) => DropdownMenuItem(
            value: i,
            child:
            Text(i.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 13)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}