import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DonorVerificationScreen extends StatefulWidget {
  const DonorVerificationScreen({super.key});

  @override
  State<DonorVerificationScreen> createState() =>
      _DonorVerificationScreenState();
}

class _DonorVerificationScreenState extends State<DonorVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // 🔧 Dummy donor data (replace with Firestore query)
  final List<Map<String, dynamic>> _donors = [
    {
      'id': 'u001',
      'name': 'Usman Ali',
      'email': 'usman@example.com',
      'phone': '03001234567',
      'bloodGroup': 'O+',
      'location': 'Lahore',
      'status': 'pending',
      'donations': 0,
      'joinedDate': DateTime(2025, 4, 1),
      'idCard': 'CNIC: 35202-1234567-1',
    },
    {
      'id': 'u002',
      'name': 'Sara Malik',
      'email': 'sara@example.com',
      'phone': '03119998877',
      'bloodGroup': 'A-',
      'location': 'Karachi',
      'status': 'pending',
      'donations': 0,
      'joinedDate': DateTime(2025, 3, 28),
      'idCard': 'CNIC: 42201-9876543-2',
    },
    {
      'id': 'u003',
      'name': 'Ahmed Raza',
      'email': 'ahmed@example.com',
      'phone': '03334455667',
      'bloodGroup': 'B+',
      'location': 'Islamabad',
      'status': 'verified',
      'donations': 5,
      'joinedDate': DateTime(2024, 11, 10),
      'idCard': 'CNIC: 61101-5566778-3',
    },
    {
      'id': 'u004',
      'name': 'Fatima Noor',
      'email': 'fatima@example.com',
      'phone': '03211112233',
      'bloodGroup': 'AB+',
      'location': 'Lahore',
      'status': 'verified',
      'donations': 8,
      'joinedDate': DateTime(2024, 9, 5),
      'idCard': 'CNIC: 35201-3344556-4',
    },
    {
      'id': 'u005',
      'name': 'Bilal Hassan',
      'email': 'bilal@example.com',
      'phone': '03456677889',
      'bloodGroup': 'O-',
      'location': 'Multan',
      'status': 'rejected',
      'donations': 0,
      'joinedDate': DateTime(2025, 2, 15),
      'idCard': 'CNIC: 36302-8877665-5',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterByStatus(String status) {
    return _donors.where((d) {
      final matchesStatus = d['status'] == status;
      final matchesSearch = _searchQuery.isEmpty ||
          (d['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (d['bloodGroup'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void _updateStatus(String donorId, String newStatus) {
    setState(() {
      final idx = _donors.indexWhere((d) => d['id'] == donorId);
      if (idx != -1) _donors[idx]['status'] = newStatus;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified_user;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty;
    }
  }

  int get _pendingCount =>
      _donors.where((d) => d['status'] == 'pending').length;

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
        title: Row(
          children: [
            const Text(
              'Donor Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ]
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 16),
                  const SizedBox(width: 4),
                  Text('Pending ($_pendingCount)'),
                ],
              ),
            ),
            const Tab(icon: Icon(Icons.verified_user, size: 16), text: 'Verified'),
            const Tab(icon: Icon(Icons.block, size: 16), text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name or blood group...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDonorList('pending'),
                _buildDonorList('verified'),
                _buildDonorList('rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorList(String status) {
    final donors = _filterByStatus(status);

    if (donors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _statusIcon(status),
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'No ${status} donors',
              style: const TextStyle(
                  fontSize: 17, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: donors.length,
      itemBuilder: (context, index) =>
          _buildDonorCard(donors[index], status),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor, String status) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                  child: Text(
                    donor['name'][0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        donor['email'],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Blood group badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    donor['bloodGroup'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details grid
            Row(
              children: [
                Expanded(
                    child: _buildDetail(
                        Icons.phone_outlined, 'Phone', donor['phone'])),
                Expanded(
                    child: _buildDetail(Icons.location_on_outlined,
                        'Location', donor['location'])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildDetail(Icons.badge_outlined, 'ID Card',
                        donor['idCard'])),
                Expanded(
                    child: _buildDetail(
                        Icons.volunteer_activism,
                        'Donations',
                        '${donor['donations']} times')),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetail(
              Icons.calendar_today_outlined,
              'Joined',
              '${donor['joinedDate'].day}/${donor['joinedDate'].month}/${donor['joinedDate'].year}',
            ),

            // Action buttons (only for pending)
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _updateStatus(donor['id'], 'rejected');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${donor['name']} has been rejected.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _updateStatus(donor['id'], 'verified');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${donor['name']} has been verified!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Status badge for non-pending
            if (status != 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(_statusIcon(status),
                      size: 16, color: _statusColor(status)),
                  const SizedBox(width: 6),
                  Text(
                    status == 'verified' ? 'Verified Donor' : 'Account Rejected',
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (status == 'rejected')
                    TextButton(
                      onPressed: () {
                        _updateStatus(donor['id'], 'verified');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${donor['name']} has been re-verified.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text('Re-verify',
                          style: TextStyle(color: AppColors.success)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
