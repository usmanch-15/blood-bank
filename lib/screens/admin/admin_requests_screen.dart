import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart'; // ✅ FIX (Issue #14): re-enabled
import '../../models/blood_request_model.dart';

/// Admin Requests Screen - View all blood requests
class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService(); // ✅ FIX (Issue #14): re-enabled

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Requests'),
        backgroundColor: AppColors.primaryDarkRed,
        foregroundColor: Colors.white,
      ),

      // ✅ FIX (Issue #14): StreamBuilder restored so admin can actually
      // see live blood requests instead of the "Firebase disabled" stub.
      body: StreamBuilder<List<BloodRequestModel>>(
        stream: firestoreService.getAllBloodRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('No requests found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request, firestoreService);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context,
      BloodRequestModel request,
      FirestoreService firestoreService, // ✅ FIX (Issue #14): re-enabled
      ) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(request.urgency).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.urgency.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getUrgencyColor(request.urgency),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Requested by: ${request.requesterName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.bloodtype, size: 20, color: AppColors.primaryRed),
                const SizedBox(width: 10),
                Text(
                  '${request.bloodGroup} - ${request.unitsRequired} units',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 10),
                Text(
                  dateFormat.format(request.createdAt),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            // ✅ FIX (Issue #14): restored. Only admins can reach this
            // screen, so this is the one place allowed to change a
            // request's status directly (see Issue #7 fix in
            // firestore.rules — regular requesters can no longer do this
            // themselves).
            if (request.status == 'pending') ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        firestoreService.updateBloodRequestStatus(
                          request.id,
                          'fulfilled',
                        );
                      },
                      child: const Text('Mark Fulfilled'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return AppColors.error;
      case 'urgent':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}