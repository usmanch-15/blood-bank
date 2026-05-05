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

  /// ✅ REAL LIST (not dummy)
  List<BloodRequestModel> myRequests = [];

  /// ➕ Add request function
  void addRequest(BloodRequestModel request) {
    setState(() {
      myRequests.add(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          /// 🔴 AppBar
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
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ➕ Create Request (IMPORTANT FIX)
                  _actionTile(
                    title: 'Create Blood Request',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BloodRequestFormScreen(),
                        ),
                      );

                      /// ✅ Receive data back from form
                      if (result != null &&
                          result is BloodRequestModel) {
                        addRequest(result);
                      }
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

                  /// ❗ EMPTY STATE HANDLING
                  if (myRequests.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No requests yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...myRequests.map(_requestCard).toList(),
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
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }

  /// 🩸 Request Card
  Widget _requestCard(BloodRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.bloodGroup} • ${request.unitsRequired} Units',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(request.hospitalName),
            Text(request.location),
          ],
        ),
      ),
    );
  }
}