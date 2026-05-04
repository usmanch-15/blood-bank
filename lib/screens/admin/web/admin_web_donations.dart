import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/data_table_widget.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebDonations extends StatefulWidget {
  const AdminWebDonations({Key? key}) : super(key: key);

  @override
  State<AdminWebDonations> createState() => _AdminWebDonationsState();
}

class _AdminWebDonationsState extends State<AdminWebDonations> {
  String _statusFilter = 'All';

  final List<Map<String, dynamic>> _allDonations = [
    {
      'Donation ID': 'DON-001',
      'Donor': 'Ali Hassan',
      'Blood Group': 'A+',
      'Units': '1',
      'Hospital': 'City General Hospital',
      'Status': 'completed',
      'Date': '2024-05-10',
    },
    {
      'Donation ID': 'DON-002',
      'Donor': 'Bilal Raza',
      'Blood Group': 'B+',
      'Units': '1',
      'Hospital': 'Aga Khan Hospital',
      'Status': 'pending',
      'Date': '2024-05-15',
    },
    {
      'Donation ID': 'DON-003',
      'Donor': 'Omar Sheikh',
      'Blood Group': 'A+',
      'Units': '2',
      'Hospital': 'Shaukat Khanum',
      'Status': 'completed',
      'Date': '2024-05-20',
    },
    {
      'Donation ID': 'DON-004',
      'Donor': 'Zara Iqbal',
      'Blood Group': 'AB-',
      'Units': '1',
      'Hospital': 'PIMS Hospital',
      'Status': 'pending',
      'Date': '2024-05-22',
    },
    {
      'Donation ID': 'DON-005',
      'Donor': 'Usman Ahmed',
      'Blood Group': 'O+',
      'Units': '1',
      'Hospital': 'DHQ Hospital',
      'Status': 'approved',
      'Date': '2024-05-25',
    },
    {
      'Donation ID': 'DON-006',
      'Donor': 'Nadia Siddiqui',
      'Blood Group': 'O-',
      'Units': '1',
      'Hospital': 'Services Hospital',
      'Status': 'rejected',
      'Date': '2024-05-28',
    },
    {
      'Donation ID': 'DON-007',
      'Donor': 'Ali Hassan',
      'Blood Group': 'A+',
      'Units': '1',
      'Hospital': 'City General Hospital',
      'Status': 'completed',
      'Date': '2024-06-02',
    },
    {
      'Donation ID': 'DON-008',
      'Donor': 'Hamza Tariq',
      'Blood Group': 'A-',
      'Units': '2',
      'Hospital': 'Mayo Hospital',
      'Status': 'approved',
      'Date': '2024-06-05',
    },
    {
      'Donation ID': 'DON-009',
      'Donor': 'Bilal Raza',
      'Blood Group': 'B+',
      'Units': '1',
      'Hospital': 'Aga Khan Hospital',
      'Status': 'completed',
      'Date': '2024-06-08',
    },
    {
      'Donation ID': 'DON-010',
      'Donor': 'Omar Sheikh',
      'Blood Group': 'A+',
      'Units': '1',
      'Hospital': 'Shaukat Khanum',
      'Status': 'pending',
      'Date': '2024-06-10',
    },
  ];

  List<Map<String, dynamic>> get _filteredDonations {
    if (_statusFilter == 'All') return _allDonations;
    return _allDonations
        .where((d) => d['Status'] == _statusFilter.toLowerCase())
        .toList();
  }

  int get _completedCount =>
      _allDonations.where((d) => d['Status'] == 'completed').length;
  int get _pendingCount =>
      _allDonations.where((d) => d['Status'] == 'pending').length;
  int get _totalUnits => _allDonations.fold<int>(
      0, (sum, d) => sum + (int.tryParse(d['Units'].toString()) ?? 0));

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
              'Donation ID',
              'Donor',
              'Blood Group',
              'Units',
              'Hospital',
              'Status',
              'Date',
            ],
            rows: _filteredDonations,
            searchHint: 'Search by donor name, hospital...',
            onEdit: (row) => _showVerifyDialog(context, row),
            onDelete: (row) => setState(() => _allDonations
                .removeWhere((d) => d['Donation ID'] == row['Donation ID'])),
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
              'Donation Records',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Track and verify all blood donation records',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showVerifyDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
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
          title: 'Total Donations',
          value: '${_allDonations.length}',
          icon: Icons.favorite,
          color: Colors.red,
          percentage: '+8%',
        ),
        StatCardWidget(
          title: 'Completed',
          value: '$_completedCount',
          icon: Icons.task_alt,
          color: Colors.green,
          percentage: '+12%',
        ),
        StatCardWidget(
          title: 'Pending Verification',
          value: '$_pendingCount',
          icon: Icons.pending_actions,
          color: Colors.orange,
          percentage: '+3%',
        ),
        StatCardWidget(
          title: 'Total Units',
          value: '$_totalUnits',
          icon: Icons.water_drop,
          color: Colors.blue,
          percentage: '+9%',
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Completed', 'Approved', 'Pending', 'Rejected'];
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

  void _showVerifyDialog(BuildContext context, Map<String, dynamic>? existing) {
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Verify Donation' : 'Add Donation Record'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEdit) ...[
                _buildInfoRow('Donor', existing['Donor']),
                _buildInfoRow('Blood Group', existing['Blood Group']),
                _buildInfoRow('Hospital', existing['Hospital']),
                _buildInfoRow('Date', existing['Date']),
                const SizedBox(height: 16),
                const Text('Update verification status:'),
                const SizedBox(height: 8),
              ],
              DropdownButtonFormField<String>(
                value: existing?['Status'] ?? 'pending',
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['pending', 'approved', 'completed', 'rejected']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isEdit ? 'Update Status' : 'Add Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
