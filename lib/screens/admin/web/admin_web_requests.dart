import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/data_table_widget.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebRequests extends StatefulWidget {
  const AdminWebRequests({Key? key}) : super(key: key);

  @override
  State<AdminWebRequests> createState() => _AdminWebRequestsState();
}

class _AdminWebRequestsState extends State<AdminWebRequests> {
  String _statusFilter = 'All';

  final List<Map<String, dynamic>> _allRequests = [
    {
      'Request ID': 'REQ-001',
      'Patient': 'Kamran Ali',
      'Blood Group': 'A+',
      'Units': '2',
      'Urgency': 'High',
      'Status': 'pending',
      'Date': '2024-06-01',
    },
    {
      'Request ID': 'REQ-002',
      'Patient': 'Sana Mirza',
      'Blood Group': 'B-',
      'Units': '1',
      'Urgency': 'Critical',
      'Status': 'approved',
      'Date': '2024-06-02',
    },
    {
      'Request ID': 'REQ-003',
      'Patient': 'Tariq Mehmood',
      'Blood Group': 'O+',
      'Units': '3',
      'Urgency': 'Medium',
      'Status': 'completed',
      'Date': '2024-06-03',
    },
    {
      'Request ID': 'REQ-004',
      'Patient': 'Rida Qureshi',
      'Blood Group': 'AB+',
      'Units': '1',
      'Urgency': 'Low',
      'Status': 'rejected',
      'Date': '2024-06-04',
    },
    {
      'Request ID': 'REQ-005',
      'Patient': 'Adeel Farooq',
      'Blood Group': 'O-',
      'Units': '2',
      'Urgency': 'High',
      'Status': 'pending',
      'Date': '2024-06-05',
    },
    {
      'Request ID': 'REQ-006',
      'Patient': 'Madiha Noor',
      'Blood Group': 'B+',
      'Units': '4',
      'Urgency': 'Critical',
      'Status': 'approved',
      'Date': '2024-06-06',
    },
    {
      'Request ID': 'REQ-007',
      'Patient': 'Imran Shah',
      'Blood Group': 'A-',
      'Units': '1',
      'Urgency': 'Medium',
      'Status': 'completed',
      'Date': '2024-06-07',
    },
    {
      'Request ID': 'REQ-008',
      'Patient': 'Lubna Rashid',
      'Blood Group': 'AB-',
      'Units': '2',
      'Urgency': 'High',
      'Status': 'pending',
      'Date': '2024-06-08',
    },
  ];

  List<Map<String, dynamic>> get _filteredRequests {
    if (_statusFilter == 'All') return _allRequests;
    return _allRequests
        .where((r) => r['Status'] == _statusFilter.toLowerCase())
        .toList();
  }

  int get _pendingCount =>
      _allRequests.where((r) => r['Status'] == 'pending').length;
  int get _approvedCount =>
      _allRequests.where((r) => r['Status'] == 'approved').length;
  int get _completedCount =>
      _allRequests.where((r) => r['Status'] == 'completed').length;

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
              'Request ID',
              'Patient',
              'Blood Group',
              'Units',
              'Urgency',
              'Status',
              'Date',
            ],
            rows: _filteredRequests,
            searchHint: 'Search by patient name, blood group...',
            onEdit: (row) => _showRequestDialog(context, row),
            onDelete: (row) => setState(() => _allRequests
                .removeWhere((r) => r['Request ID'] == row['Request ID'])),
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
              'Blood Requests',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Monitor and manage all blood donation requests',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showRequestDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text('New Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
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
          title: 'Total Requests',
          value: '${_allRequests.length}',
          icon: Icons.bloodtype,
          color: Colors.red,
          percentage: '+5%',
        ),
        StatCardWidget(
          title: 'Pending',
          value: '$_pendingCount',
          icon: Icons.hourglass_empty,
          color: Colors.orange,
          percentage: '+2%',
        ),
        StatCardWidget(
          title: 'Approved',
          value: '$_approvedCount',
          icon: Icons.check_circle_outline,
          color: Colors.blue,
          percentage: '+10%',
        ),
        StatCardWidget(
          title: 'Completed',
          value: '$_completedCount',
          icon: Icons.task_alt,
          color: Colors.green,
          percentage: '+8%',
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

  void _showRequestDialog(BuildContext context, Map<String, dynamic>? existing) {
    final patientController =
        TextEditingController(text: existing?['Patient'] ?? '');
    final unitsController =
        TextEditingController(text: existing?['Units'] ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Request' : 'New Blood Request'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Units Required',
                  border: OutlineInputBorder(),
                ),
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
            child: Text(isEdit ? 'Save Changes' : 'Create Request'),
          ),
        ],
      ),
    );
  }
}
