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
  final String userId = 'user123';

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
      // or real GPS accuracy if used

      createdAt: DateTime.now(), contactNumber: '',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          /// 🔴 Advanced AppBar with Back Arrow in Title
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Receiver Dashboard',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  /// 🌈 Welcome Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryBlue,
                          AppColors.primaryRed.withOpacity(0.8),
                        ],
                      ),
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
                  ),

                  const SizedBox(height: 25),

                  /// 🚨 SOS Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.warning, size: 28),
                    label: const Text(
                      'SOS EMERGENCY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SosEmergencyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ➕ Create Request
                  _actionTile(
                    title: 'Create Blood Request',
                    icon: Icons.add_circle_outline,
                    color: AppColors.secondaryBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const BloodRequestFormScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'My Requests',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...dummyRequests.map(_requestCard).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 Action Tile
  Widget _actionTile({
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

  /// 🩸 Request Card
  Widget _requestCard(BloodRequestModel request) {
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
                const Icon(Icons.local_hospital, size: 16),
                const SizedBox(width: 6),
                Text(request.hospitalName),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
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
