import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminWebRequests extends StatefulWidget {
  const AdminWebRequests({Key? key}) : super(key: key);

  @override
  State<AdminWebRequests> createState() => _AdminWebRequestsState();
}

class _AdminWebRequestsState extends State<AdminWebRequests>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                Tab(
                  icon: Icon(Icons.bloodtype),
                  text: 'Blood Requests',
                ),
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
  const _PendingUsersTab({Key? key}) : super(key: key);

  Future<void> _approveUser(String uid, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'status': 'approved'});

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
      builder: (ctx) => AlertDialog(
        title: const Text('Reject User?'),
        content: const Text(
            'Kya aap is user ko reject karna chahte hain? Yeh wapas login nahi kar sakega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
            const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'status': 'rejected'});

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
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green.shade300),
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
                  borderRadius: BorderRadius.circular(14)),
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
                        (d['name'] ?? 'U')[0].toUpperCase(),
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
                                color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (d['bloodGroup'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
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
                              if (d['phoneNumber'] != null)
                                Text(
                                  d['phoneNumber'],
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
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
                          horizontal: 12, vertical: 4),
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
                            borderRadius: BorderRadius.circular(8)),
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
                            borderRadius: BorderRadius.circular(8)),
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
  const _BloodRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blood_requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
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
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    d['bloodGroup'] ?? '?',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(d['patientName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(d['hospital'] ?? ''),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'pending'
                        ? Colors.orange.shade50
                        : status == 'fulfilled'
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'pending'
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