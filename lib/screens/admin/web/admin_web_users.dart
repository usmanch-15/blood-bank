import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../constants/app_colors.dart';

class AdminWebUsers extends StatefulWidget {
  const AdminWebUsers({Key? key}) : super(key: key);

  @override
  State<AdminWebUsers> createState() => _AdminWebUsersState();
}

class _AdminWebUsersState extends State<AdminWebUsers>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'All';

  final List<String> _roles = ['All', 'donor', 'receiver', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage donors, receivers and admin accounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Stats chips
              _buildStatChip('pending'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Search + Filter Bar ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or blood group...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade400, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Role filter
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r == 'All' ? 'All Roles' : r[0].toUpperCase() + r.substring(1),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _roleFilter = v!),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Tabs ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.red.shade700,
              indicatorWeight: 3,
              labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top, size: 16),
                      SizedBox(width: 6),
                      Text('Pending'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Approved'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Tab Content ─────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserTable('pending'),
              _buildUserTable('approved'),
              _buildUserTable('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stat chip showing pending count ──────────────────────────
  Widget _buildStatChip(String status) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getUsersByStatus(status),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.pending_actions,
                  color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                '$count Pending Approval',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Main user table ──────────────────────────────────────────
  Widget _buildUserTable(String status) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getUsersByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade400)),
              ],
            ),
          );
        }

        var users = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            return u.name.toLowerCase().contains(_searchQuery) ||
                u.email.toLowerCase().contains(_searchQuery) ||
                (u.bloodGroup?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        // Apply role filter
        if (_roleFilter != 'All') {
          users = users.where((u) => u.role == _roleFilter).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.hourglass_empty
                      : status == 'approved'
                      ? Icons.people_outline
                      : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No users match your search'
                      : status == 'pending'
                      ? 'No pending approvals'
                      : status == 'approved'
                      ? 'No approved users'
                      : 'No rejected users',
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row count
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${users.length} user${users.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                            Colors.grey.shade50),
                        headingTextStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                        ),
                        columnSpacing: 24,
                        horizontalMargin: 20,
                        columns: const [
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Blood Group')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Joined')),
                          DataColumn(label: Text('Eligibility')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: users
                            .map((user) => _buildDataRow(user, status))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(UserModel user, String status) {
    return DataRow(
      cells: [
        // ── User name + email ──
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red.shade100,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Role ──
        DataCell(_buildRoleBadge(user.role)),

        // ── Blood Group ──
        DataCell(
          user.bloodGroup != null
              ? Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              user.bloodGroup!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
              : Text('—', style: TextStyle(color: Colors.grey.shade400)),
        ),

        // ── Location ──
        DataCell(
          Text(
            user.location ?? '—',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ── Joined date ──
        DataCell(
          Text(
            _formatDate(user.createdAt),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),

        // ── Eligibility ──
        DataCell(
          user.role == 'donor'
              ? Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: user.isEligible
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.isEligible ? 'Eligible' : 'Not Eligible',
              style: TextStyle(
                color: user.isEligible
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              : Text('—', style: TextStyle(color: Colors.grey.shade400)),
        ),

        // ── Actions ──
        DataCell(
          Row(
            children: [
              if (status == 'pending') ...[
                _actionButton(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  tooltip: 'Approve',
                  onTap: () => _updateStatus(user.uid, 'approved', user.name),
                ),
                const SizedBox(width: 6),
                _actionButton(
                  icon: Icons.cancel,
                  color: Colors.red,
                  tooltip: 'Reject',
                  onTap: () => _updateStatus(user.uid, 'rejected', user.name),
                ),
              ] else if (status == 'approved') ...[
                _actionButton(
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  tooltip: 'View Details',
                  onTap: () => _showUserDetails(user),
                ),
                const SizedBox(width: 6),
                _actionButton(
                  icon: Icons.block,
                  color: Colors.orange,
                  tooltip: 'Reject / Suspend',
                  onTap: () => _updateStatus(user.uid, 'rejected', user.name),
                ),
              ] else if (status == 'rejected') ...[
                _actionButton(
                  icon: Icons.restore,
                  color: Colors.green,
                  tooltip: 'Re-approve',
                  onTap: () => _updateStatus(user.uid, 'approved', user.name),
                ),
                const SizedBox(width: 6),
                _actionButton(
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  tooltip: 'View Details',
                  onTap: () => _showUserDetails(user),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    switch (role) {
      case 'donor':
        color = Colors.red;
        icon = Icons.favorite;
        break;
      case 'receiver':
        color = Colors.blue;
        icon = Icons.person_search;
        break;
      case 'admin':
        color = Colors.purple;
        icon = Icons.admin_panel_settings;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            role[0].toUpperCase() + role.substring(1),
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Firestore update ─────────────────────────────────────────
  Future<void> _updateStatus(
      String uid, String newStatus, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              newStatus == 'approved'
                  ? Icons.check_circle
                  : newStatus == 'rejected'
                  ? Icons.cancel
                  : Icons.restore,
              color: newStatus == 'approved'
                  ? Colors.green
                  : newStatus == 'rejected'
                  ? Colors.red
                  : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(
              newStatus == 'approved'
                  ? 'Approve User'
                  : newStatus == 'rejected'
                  ? 'Reject User'
                  : 'Re-approve User',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to ${newStatus == "approved" ? "approve" : newStatus == "rejected" ? "reject" : "re-approve"} "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'approved'
                  ? Colors.green
                  : newStatus == 'rejected'
                  ? Colors.red
                  : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus == 'approved'
                ? 'Approve'
                : newStatus == 'rejected'
                ? 'Reject'
                : 'Re-approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$name has been ${newStatus == "approved" ? "approved ✓" : newStatus == "rejected" ? "rejected ✗" : "re-approved ✓"}'),
            backgroundColor:
            newStatus == 'rejected' ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── User detail dialog ────────────────────────────────────────
  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.red.shade100,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(user.email,
                            style:
                            TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        _buildRoleBadge(user.role),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: 28),

              // Details grid
              _detailRow(Icons.bloodtype, 'Blood Group',
                  user.bloodGroup ?? 'Not specified'),
              _detailRow(Icons.phone, 'Phone',
                  user.phoneNumber ?? 'Not provided'),
              _detailRow(Icons.location_on, 'Location',
                  user.location ?? 'Not specified'),
              _detailRow(Icons.stars, 'Reward Points',
                  '${user.rewardPoints} pts'),
              _detailRow(
                  Icons.calendar_today,
                  'Joined',
                  _formatDate(user.createdAt)),
              if (user.lastDonationDate != null)
                _detailRow(
                    Icons.favorite,
                    'Last Donation',
                    _formatDate(user.lastDonationDate!)),
              _detailRow(
                  Icons.verified_user,
                  'Status',
                  user.status[0].toUpperCase() + user.status.substring(1)),
              if (user.role == 'donor')
                _detailRow(
                    Icons.health_and_safety,
                    'Eligible to Donate',
                    user.isEligible ? 'Yes ✓' : 'No — cooling period'),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}