import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'blood_request_form_screen.dart';
import 'sos_emergency_screen.dart';
import '../../models/blood_request_model.dart';

class ReceiverDashboardScreen extends StatefulWidget {
  const ReceiverDashboardScreen({super.key});

  @override
  State<ReceiverDashboardScreen> createState() =>
      _ReceiverDashboardScreenState();
}

class _ReceiverDashboardScreenState extends State<ReceiverDashboardScreen> {
  final List<BloodRequestModel> dummyRequests = [
    BloodRequestModel(
      id: '1',
      requesterId: 'user123',
      requesterName: 'Usman',
      requesterPhone: '03044009797',
      patientName: 'Ali',
      patientAge: 25,
      patientGender: 'Male',
      bloodGroup: 'O+',
      unitsRequired: 2,
      hospitalName: 'City Hospital',
      hospitalAddress: 'Lahore, Main Road',
      location: 'Lahore',
      reason: 'Accident emergency',
      requiredBy: DateTime.now().add(const Duration(hours: 3)),
      urgency: 'urgent',
      status: 'pending',
      notes: 'Please deliver quickly',
      createdAt: DateTime.now(),
      contactNumber: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Receiver Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildSosButton(context),
            const SizedBox(height: 16),
            _buildActionTile(
              title: 'Create Blood Request',
              icon: Icons.add_circle_outline,
              color: AppColors.primaryRed,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BloodRequestFormScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Requests',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...dummyRequests.map(_buildRequestCard),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Blood?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Create a request or use SOS for emergencies',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.warning, size: 28),
        label: const Text(
          'SOS EMERGENCY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SosEmergencyScreen()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge(request.urgency, _urgencyColor(request.urgency)),
                const Spacer(),
                _badge(request.status, _statusColor(request.status)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${request.bloodGroup} • ${request.unitsRequired} Units',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_hospital, size: 16,
                    color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(request.hospitalName),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16,
                    color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(request.location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _urgencyColor(String urgency) =>
      urgency == 'urgent' ? AppColors.warning : AppColors.info;

  Color _statusColor(String status) =>
      status == 'fulfilled' ? AppColors.success : AppColors.warning;
}
