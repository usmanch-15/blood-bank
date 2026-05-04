import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/blood_request_model.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _statusFilter = 'All';

  final List<BloodRequestModel> _requests = [
    BloodRequestModel(
      id: 'REQ-001',
      requesterId: 'u1',
      requesterName: 'Kamran Ali',
      requesterPhone: '03001234567',
      patientName: 'Kamran Ali',
      patientAge: 34,
      patientGender: 'Male',
      bloodGroup: 'A+',
      unitsRequired: 2,
      hospitalName: 'City Hospital',
      hospitalAddress: 'Main Boulevard, Lahore',
      location: 'Lahore',
      reason: 'Surgery',
      requiredBy: DateTime.now().add(const Duration(hours: 6)),
      urgency: 'urgent',
      status: 'pending',
      notes: '',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      contactNumber: '03001234567',
    ),
    BloodRequestModel(
      id: 'REQ-002',
      requesterId: 'u2',
      requesterName: 'Sana Mirza',
      requesterPhone: '03119876543',
      patientName: 'Sana Mirza',
      patientAge: 28,
      patientGender: 'Female',
      bloodGroup: 'B-',
      unitsRequired: 1,
      hospitalName: 'General Hospital',
      hospitalAddress: 'Garden Town, Karachi',
      location: 'Karachi',
      reason: 'Accident',
      requiredBy: DateTime.now().add(const Duration(hours: 2)),
      urgency: 'emergency',
      status: 'approved',
      notes: 'Critical condition',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      contactNumber: '03119876543',
    ),
    BloodRequestModel(
      id: 'REQ-003',
      requesterId: 'u3',
      requesterName: 'Tariq Mehmood',
      requesterPhone: '03334455667',
      patientName: 'Tariq Mehmood',
      patientAge: 50,
      patientGender: 'Male',
      bloodGroup: 'O+',
      unitsRequired: 3,
      hospitalName: 'PIMS Hospital',
      hospitalAddress: 'Islamabad',
      location: 'Islamabad',
      reason: 'Chronic illness',
      requiredBy: DateTime.now().add(const Duration(days: 1)),
      urgency: 'normal',
      status: 'fulfilled',
      notes: '',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      contactNumber: '03334455667',
    ),
    BloodRequestModel(
      id: 'REQ-004',
      requesterId: 'u4',
      requesterName: 'Rida Qureshi',
      requesterPhone: '03215544332',
      patientName: 'Rida Qureshi',
      patientAge: 22,
      patientGender: 'Female',
      bloodGroup: 'AB+',
      unitsRequired: 1,
      hospitalName: 'Shaukat Khanum',
      hospitalAddress: 'Gulberg, Lahore',
      location: 'Lahore',
      reason: 'Cancer treatment',
      requiredBy: DateTime.now().add(const Duration(days: 3)),
      urgency: 'normal',
      status: 'pending',
      notes: 'Ongoing treatment',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      contactNumber: '03215544332',
    ),
    BloodRequestModel(
      id: 'REQ-005',
      requesterId: 'u5',
      requesterName: 'Adeel Farooq',
      requesterPhone: '03451122334',
      patientName: 'Adeel Farooq',
      patientAge: 40,
      patientGender: 'Male',
      bloodGroup: 'O-',
      unitsRequired: 2,
      hospitalName: 'Aga Khan Hospital',
      hospitalAddress: 'Stadium Road, Karachi',
      location: 'Karachi',
      reason: 'Heart surgery',
      requiredBy: DateTime.now().add(const Duration(hours: 12)),
      urgency: 'urgent',
      status: 'pending',
      notes: 'Rare blood group needed',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      contactNumber: '03451122334',
    ),
  ];

  List<BloodRequestModel> get _filtered {
    if (_statusFilter == 'All') return _requests;
    return _requests
        .where((r) => r.status.toLowerCase() == _statusFilter.toLowerCase())
        .toList();
  }

  void _updateStatus(BloodRequestModel req, String newStatus) {
    setState(() {
      final idx = _requests.indexWhere((r) => r.id == req.id);
      if (idx != -1) {
        _requests[idx] = BloodRequestModel(
          id: req.id,
          requesterId: req.requesterId,
          requesterName: req.requesterName,
          requesterPhone: req.requesterPhone,
          patientName: req.patientName,
          patientAge: req.patientAge,
          patientGender: req.patientGender,
          bloodGroup: req.bloodGroup,
          unitsRequired: req.unitsRequired,
          hospitalName: req.hospitalName,
          hospitalAddress: req.hospitalAddress,
          location: req.location,
          reason: req.reason,
          requiredBy: req.requiredBy,
          urgency: req.urgency,
          status: newStatus,
          notes: req.notes,
          createdAt: req.createdAt,
          contactNumber: req.contactNumber,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, HH:mm');
    final pending = _requests.where((r) => r.status == 'pending').length;
    final approved = _requests.where((r) => r.status == 'approved').length;
    final fulfilled = _requests.where((r) => r.status == 'fulfilled').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Blood Requests',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: AppColors.primaryRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _statChip('Total', '${_requests.length}', Colors.white),
                _statChip('Pending', '$pending', Colors.orange.shade200),
                _statChip('Approved', '$approved', Colors.green.shade200),
                _statChip('Fulfilled', '$fulfilled', Colors.blue.shade200),
              ],
            ),
          ),
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'Approved', 'Fulfilled']
                    .map((s) {
                  final sel = _statusFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (_) => setState(() => _statusFilter = s),
                      selectedColor: AppColors.primaryRed.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: sel
                            ? AppColors.primaryRed
                            : AppColors.textSecondary,
                        fontWeight:
                            sel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No requests found',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildCard(_filtered[i], fmt),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BloodRequestModel req, DateFormat fmt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge(req.urgency, _urgencyColor(req.urgency)),
                const Spacer(),
                _badge(req.status, _statusColor(req.status)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${req.bloodGroup} · ${req.unitsRequired} units needed',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.person, req.requesterName),
            _infoRow(Icons.local_hospital, req.hospitalName),
            _infoRow(Icons.location_on, req.location),
            _infoRow(Icons.access_time, fmt.format(req.createdAt)),
            if (req.notes.isNotEmpty)
              _infoRow(Icons.notes, req.notes),
            if (req.status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(req, 'approved'),
                      icon: const Icon(Icons.check, size: 18,
                          color: Colors.green),
                      label: const Text('Approve',
                          style: TextStyle(color: Colors.green)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(req, 'cancelled'),
                      icon: const Icon(Icons.close, size: 18,
                          color: Colors.red),
                      label: const Text('Reject',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (req.status == 'approved') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(req, 'fulfilled'),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Mark Fulfilled'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _urgencyColor(String u) {
    switch (u.toLowerCase()) {
      case 'emergency':
        return AppColors.error;
      case 'urgent':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'fulfilled':
        return AppColors.success;
      case 'approved':
        return Colors.blue;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
