import '../../../services/workflow_service.dart';
import '../../requests/request_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> showAdminRequestDetails(
  BuildContext context,
  DocumentReference ref,
  Map<String, dynamic> data, {
  bool sos = false,
}) async {
  final action = await showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(sos ? 'SOS request' : 'Blood request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field
                    in (sos
                        ? [
                          'receiverId',
                          'bloodGroup',
                          'urgency',
                          'latitude',
                          'longitude',
                          'status',
                          'isResolved',
                          'radiusKm',
                          'notifiedDonors',
                        ]
                        : [
                          'patientName',
                          'patientAge',
                          'bloodGroup',
                          'quantity',
                          'hospitalName',
                          'hospitalAddress',
                          'contactNumber',
                          'requiredBy',
                          'status',
                          'acceptedDonorId',
                          'notifiedDonors',
                        ]))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('$field: ${data[field] ?? 'Not provided'}'),
                  ),
              ],
            ),
          ),
          actions: [
            if (!sos)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestTrackingScreen(requestId: ref.id),
                    ),
                  );
                },
                child: const Text('Track / Manage donors'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (sos
                ? data['isResolved'] != true
                : ['pending', 'accepted'].contains(data['status']))
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'update'),
                child: Text(sos ? 'Resolve SOS' : 'Cancel request'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Archive'),
            ),
          ],
        ),
  );
  if (action == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(
            action == 'delete'
                ? 'Archive this record?'
                : sos
                ? 'Resolve this SOS?'
                : 'Cancel this request?',
          ),
          content: Text(
            action == 'delete'
                ? 'This closes the request and preserves its history for audit.'
                : 'The requester will see the updated status.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep record'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
  );
  if (confirmed != true) return;
  try {
    await WorkflowService.call('adminRequestAction', {
      'id': ref.id,
      'sos': sos,
      'action': action == 'delete' ? 'archive' : 'close',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated successfully.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update request: $e')));
    }
  }
}

class AdminEmergencyRequests extends StatelessWidget {
  const AdminEmergencyRequests({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream:
        FirebaseFirestore.instance
            .collection('sosRequests')
            .orderBy('triggerTime', descending: true)
            .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('Unable to load SOS requests: ${snapshot.error}'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return const Center(child: Text('No SOS requests.'));
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index], data = doc.data();
          return ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: Text(
              '${data['bloodGroup']} • ${data['urgency'] ?? 'critical'}',
            ),
            subtitle: Text(
              '${data['receiverId']} • ${data['status'] ?? 'Queued'}',
            ),
            trailing: Text(data['isResolved'] == true ? 'Resolved' : 'Open'),
            onTap:
                () => showAdminRequestDetails(
                  context,
                  doc.reference,
                  data,
                  sos: true,
                ),
          );
        },
      );
    },
  );
}

class AdminWebRequests extends StatefulWidget {
  const AdminWebRequests({super.key});

  @override
  State<AdminWebRequests> createState() => _AdminWebRequestsState();
}

class _AdminWebRequestsState extends State<AdminWebRequests>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ── Tab Bar ──
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red.shade700,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_add_alt_1),
                  text: 'User Approval Requests',
                ),
                Tab(icon: Icon(Icons.bloodtype), text: 'Blood Requests'),
                Tab(icon: Icon(Icons.emergency), text: 'SOS Requests'),
              ],
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PendingUsersTab(),
                _BloodRequestsTab(),
                AdminEmergencyRequests(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 1: Pending User Approvals
// ════════════════════════════════════════════════════════════════
class _PendingUsersTab extends StatelessWidget {
  const _PendingUsersTab();

  Future<void> _approveUser(String uid, BuildContext context) async {
    await WorkflowService.call('adminAction', {
      'collection': 'users',
      'id': uid,
      'updates': {'status': 'approved'},
    });
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ User approved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectUser(String uid, BuildContext context) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reject User?'),
            content: const Text(
              'Kya aap is user ko reject karna chahte hain? Yeh wapas login nahi kar sakega.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await WorkflowService.call('adminAction', {
        'collection': 'users',
        'id': uid,
        'updates': {'status': 'rejected'},
      });
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User rejected.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Unable to load records: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Koi pending request nahi!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sab users approve ya reject ho chuke hain.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ── Avatar ──
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange.shade50,
                      child: Text(
                        (d['name']?.toString().isNotEmpty == true
                                ? d['name'][0]
                                : 'U')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ── User Info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['email'] ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (d['bloodGroup'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    d['bloodGroup'],
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // ✅ FIX: blood_requests docs never had a
                              // 'phoneNumber' field — the form saves it as
                              // 'contactNumber' (see blood_request_form_screen.dart
                              // and BloodRequestModel). This was always
                              // silently showing nothing.
                              if (d['contactNumber'] != null &&
                                  d['contactNumber'].toString().isNotEmpty)
                                Text(
                                  d['contactNumber'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Status Badge ──
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // ── Action Buttons ──
                    ElevatedButton.icon(
                      onPressed: () => _approveUser(uid, context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _rejectUser(uid, context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 2: Blood Requests (aapka purana content yahan)
// ════════════════════════════════════════════════════════════════
class _BloodRequestsTab extends StatelessWidget {
  const _BloodRequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Unable to load requests: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Koi blood request nahi abhi tak.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final status = d['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    d['bloodGroup'] ?? '?',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  d['patientName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(d['hospitalName'] ?? ''),
                onTap:
                    () => showAdminRequestDetails(
                      context,
                      docs[index].reference,
                      d,
                    ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        status == 'pending'
                            ? Colors.orange.shade50
                            : status == 'fulfilled'
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color:
                          status == 'pending'
                              ? Colors.orange.shade700
                              : status == 'fulfilled'
                              ? Colors.green.shade700
                              : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
