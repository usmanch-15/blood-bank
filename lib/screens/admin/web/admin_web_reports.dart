import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/data_table_widget.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebReports extends StatefulWidget {
  const AdminWebReports({Key? key}) : super(key: key);

  @override
  State<AdminWebReports> createState() => _AdminWebReportsState();
}

class _AdminWebReportsState extends State<AdminWebReports> {
  String _statusFilter = 'All';

  final List<Map<String, dynamic>> _allReports = [
    {
      'Report ID': 'RPT-001',
      'Reporter': 'Sara Khan',
      'Reported User': 'John Doe',
      'Reason': 'Fake donation claim',
      'Status': 'pending',
      'Date': '2024-05-12',
    },
    {
      'Report ID': 'RPT-002',
      'Reporter': 'Hamza Tariq',
      'Reported User': 'Mike Smith',
      'Reason': 'No-show after confirmation',
      'Status': 'approved',
      'Date': '2024-05-14',
    },
    {
      'Report ID': 'RPT-003',
      'Reporter': 'Fatima Malik',
      'Reported User': 'Ahmed Raza',
      'Reason': 'Abusive behaviour',
      'Status': 'completed',
      'Date': '2024-05-16',
    },
    {
      'Report ID': 'RPT-004',
      'Reporter': 'Bilal Raza',
      'Reported User': 'Nadia Gill',
      'Reason': 'False blood group info',
      'Status': 'rejected',
      'Date': '2024-05-18',
    },
    {
      'Report ID': 'RPT-005',
      'Reporter': 'Zara Iqbal',
      'Reported User': 'Tariq Mehmood',
      'Reason': 'Repeated no-shows',
      'Status': 'pending',
      'Date': '2024-05-20',
    },
    {
      'Report ID': 'RPT-006',
      'Reporter': 'Ali Hassan',
      'Reported User': 'Sana Mirza',
      'Reason': 'Soliciting payment for donation',
      'Status': 'approved',
      'Date': '2024-05-22',
    },
    {
      'Report ID': 'RPT-007',
      'Reporter': 'Hina Baig',
      'Reported User': 'Omar Sheikh',
      'Reason': 'Harassment',
      'Status': 'pending',
      'Date': '2024-05-25',
    },
    {
      'Report ID': 'RPT-008',
      'Reporter': 'Usman Ahmed',
      'Reported User': 'Rida Qureshi',
      'Reason': 'Spam messages',
      'Status': 'completed',
      'Date': '2024-05-28',
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    if (_statusFilter == 'All') return _allReports;
    return _allReports
        .where((r) => r['Status'] == _statusFilter.toLowerCase())
        .toList();
  }

  int get _pendingCount =>
      _allReports.where((r) => r['Status'] == 'pending').length;
  int get _resolvedCount =>
      _allReports.where((r) => r['Status'] == 'completed').length;
  int get _dismissedCount =>
      _allReports.where((r) => r['Status'] == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 16),
          DataTableWidget(
            columns: const [
              'Report ID',
              'Reporter',
              'Reported User',
              'Reason',
              'Status',
              'Date',
            ],
            rows: _filteredReports,
            searchHint: 'Search by reporter, reported user, reason...',
            onEdit: (row) => _showReportDetailDialog(context, row),
            onDelete: (row) => setState(() => _allReports
                .removeWhere((r) => r['Report ID'] == row['Report ID'])),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Misuse Reports',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Review and resolve user complaints and misuse reports',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: const Text('Export Report'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCardWidget(
          title: 'Total Reports',
          value: '${_allReports.length}',
          icon: Icons.report,
          color: Colors.red,
          percentage: '+2%',
        ),
        StatCardWidget(
          title: 'Pending Review',
          value: '$_pendingCount',
          icon: Icons.pending_actions,
          color: Colors.orange,
          percentage: '+1%',
        ),
        StatCardWidget(
          title: 'Resolved',
          value: '$_resolvedCount',
          icon: Icons.check_circle,
          color: Colors.green,
          percentage: '+20%',
        ),
        StatCardWidget(
          title: 'Dismissed',
          value: '$_dismissedCount',
          icon: Icons.cancel,
          color: Colors.grey,
          percentage: '-5%',
          isIncrease: false,
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Pending', 'Approved', 'Completed', 'Rejected'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _statusFilter = filter),
              selectedColor: Colors.red.shade50,
              checkmarkColor: Colors.red.shade700,
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReportDetailDialog(
      BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text('Report ${report['Report ID']}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Reporter', report['Reporter']),
              _buildDetailRow('Reported User', report['Reported User']),
              _buildDetailRow('Reason', report['Reason']),
              _buildDetailRow('Date Filed', report['Date']),
              _buildDetailRow('Current Status', report['Status']),
              const Divider(height: 24),
              Text(
                'Update Status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _actionButton(
                    context,
                    'Approve',
                    Colors.green,
                    Icons.check,
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    context,
                    'Dismiss',
                    Colors.grey,
                    Icons.cancel,
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    context,
                    'Ban User',
                    Colors.red,
                    Icons.block,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
