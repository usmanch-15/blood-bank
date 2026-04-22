import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';

/// Blood Drive Alerts Screen
class BloodDriveAlertsScreen extends StatefulWidget {
  const BloodDriveAlertsScreen({super.key});

  @override
  State<BloodDriveAlertsScreen> createState() => _BloodDriveAlertsScreenState();
}

class _BloodDriveAlertsScreenState extends State<BloodDriveAlertsScreen> {
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Drives'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BloodDriveModel>>(
        stream: _firestoreService.getAllBloodDrives(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final drives = snapshot.data ?? <BloodDriveModel>[];

          if (drives.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No blood drives scheduled'),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for upcoming drives',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drives.length,
            itemBuilder: (context, index) {
              final drive = drives[index];
              return _buildBloodDriveCard(drive);
            },
          );
        },
      ),
    );
  }

  Widget _buildBloodDriveCard(dynamic drive) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final progress = (drive.currentDonations / drive.targetDonations)
        .clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.primaryRed,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.title ?? 'Blood Drive',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drive.location ?? 'Location TBD',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Date and Time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(drive.startDate ?? DateTime.now()),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 20),
                Icon(Icons.access_time, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  '${timeFormat.format(drive.startDate ?? DateTime.now())} - ${timeFormat.format(drive.endDate ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Blood Groups Needed
            Wrap(
              spacing: 8,
              children: (drive.bloodGroupsNeeded ?? ['O+', 'O-', 'A+'])
                  .take(4)
                  .map((group) => Chip(
                        label: Text(group),
                        backgroundColor: AppColors.primaryRed.withOpacity(0.2),
                        labelStyle: const TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${drive.currentDonations ?? 0}/${drive.targetDonations ?? 100}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening location...')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 4),
                        Text('Map'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registered for drive')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 16),
                        SizedBox(width: 4),
                        Text('Register'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
