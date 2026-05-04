import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class DonorVerificationScreen extends StatefulWidget {
  const DonorVerificationScreen({super.key});

  @override
  State<DonorVerificationScreen> createState() =>
      _DonorVerificationScreenState();
}

class _DonorVerificationScreenState extends State<DonorVerificationScreen> {
  String _filterStatus = 'All';

  final List<_PendingDonor> _donors = [
    _PendingDonor(
      id: 'VER-001',
      name: 'Ali Hassan',
      email: 'ali.hassan@gmail.com',
      bloodGroup: 'O+',
      phone: '03001234567',
      location: 'Lahore, Punjab',
      submittedAt: DateTime(2024, 5, 20),
      status: 'pending',
      idCard: 'CNIC-3520112345678',
    ),
    _PendingDonor(
      id: 'VER-002',
      name: 'Sara Khan',
      email: 'sara.khan@gmail.com',
      bloodGroup: 'A+',
      phone: '03001234568',
      location: 'Karachi, Sindh',
      submittedAt: DateTime(2024, 5, 19),
      status: 'pending',
      idCard: 'CNIC-4210198765432',
    ),
    _PendingDonor(
      id: 'VER-003',
      name: 'Ahmed Raza',
      email: 'ahmed.raza@gmail.com',
      bloodGroup: 'B-',
      phone: '03001234569',
      location: 'Islamabad, FCT',
      submittedAt: DateTime(2024, 5, 18),
      status: 'approved',
      idCard: 'CNIC-6110111223344',
    ),
    _PendingDonor(
      id: 'VER-004',
      name: 'Fatima Malik',
      email: 'fatima.malik@gmail.com',
      bloodGroup: 'AB+',
      phone: '03001234570',
      location: 'Lahore, Punjab',
      submittedAt: DateTime(2024, 5, 17),
      status: 'rejected',
      idCard: 'CNIC-3520199988776',
    ),
    _PendingDonor(
      id: 'VER-005',
      name: 'Omar Sheikh',
      email: 'omar.sheikh@gmail.com',
      bloodGroup: 'O-',
      phone: '03001234571',
      location: 'Faisalabad, Punjab',
      submittedAt: DateTime(2024, 5, 16),
      status: 'pending',
      idCard: 'CNIC-3310155566677',
    ),
  ];

  List<_PendingDonor> get _filtered {
    if (_filterStatus == 'All') return _donors;
    return _donors
        .where((d) => d.status == _filterStatus.toLowerCase())
        .toList();
  }

  int get _pendingCount =>
      _donors.where((d) => d.status == 'pending').length;
  int get _approvedCount =>
      _donors.where((d) => d.status == 'approved').length;
  int get _rejectedCount =>
      _donors.where((d) => d.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          'Donor Verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildFilterChips(),
          Expanded(child: _buildDonorList()),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _statChip('Total', _donors.length, AppColors.primaryRed),
          const SizedBox(width: 8),
          _statChip('Pending', _pendingCount, AppColors.warning),
          const SizedBox(width: 8),
          _statChip('Approved', _approvedCount, AppColors.success),
          const SizedBox(width: 8),
          _statChip('Rejected', _rejectedCount, AppColors.error),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];
    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (_, index) {
          final f = filters[index];
          final isSelected = _filterStatus == f;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonorList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No donors in this category',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildDonorCard(_filtered[index]),
    );
  }

  Widget _buildDonorCard(_PendingDonor donor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                child: Text(
                  donor.name[0],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      donor.email,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(donor.status),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _infoChip(Icons.bloodtype, donor.bloodGroup),
              const SizedBox(width: 12),
              _infoChip(Icons.phone, donor.phone),
              const SizedBox(width: 12),
              Expanded(
                child: _infoChip(Icons.location_on, donor.location),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoChip(Icons.badge, donor.idCard),
              const Spacer(),
              Text(
                'Submitted: ${donor.submittedAt.day}/${donor.submittedAt.month}/${donor.submittedAt.year}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (donor.status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(donor, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text('Reject',
                        style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(donor, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Approve',
                        style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final (color, label) = switch (status) {
      'approved' => (AppColors.success, 'Approved'),
      'rejected' => (AppColors.error, 'Rejected'),
      _ => (AppColors.warning, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _updateStatus(_PendingDonor donor, String newStatus) {
    setState(() {
      final index = _donors.indexWhere((d) => d.id == donor.id);
      if (index != -1) {
        _donors[index] = _PendingDonor(
          id: donor.id,
          name: donor.name,
          email: donor.email,
          bloodGroup: donor.bloodGroup,
          phone: donor.phone,
          location: donor.location,
          submittedAt: donor.submittedAt,
          status: newStatus,
          idCard: donor.idCard,
        );
      }
    });

    final message = newStatus == 'approved'
        ? '${donor.name} approved successfully'
        : '${donor.name} rejected';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            newStatus == 'approved' ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PendingDonor {
  final String id;
  final String name;
  final String email;
  final String bloodGroup;
  final String phone;
  final String location;
  final DateTime submittedAt;
  final String status;
  final String idCard;

  const _PendingDonor({
    required this.id,
    required this.name,
    required this.email,
    required this.bloodGroup,
    required this.phone,
    required this.location,
    required this.submittedAt,
    required this.status,
    required this.idCard,
  });
}
