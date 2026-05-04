import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/data_table_widget.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebUsers extends StatefulWidget {
  const AdminWebUsers({Key? key}) : super(key: key);

  @override
  State<AdminWebUsers> createState() => _AdminWebUsersState();
}

class _AdminWebUsersState extends State<AdminWebUsers> {
  String _roleFilter = 'All';

  final List<Map<String, dynamic>> _allUsers = [
    {
      'Name': 'Ali Hassan',
      'Email': 'ali@example.com',
      'Role': 'Donor',
      'Blood Group': 'A+',
      'Status': 'active',
      'Joined': '2024-01-15',
    },
    {
      'Name': 'Sara Khan',
      'Email': 'sara@example.com',
      'Role': 'Receiver',
      'Blood Group': 'B-',
      'Status': 'active',
      'Joined': '2024-02-03',
    },
    {
      'Name': 'Usman Ahmed',
      'Email': 'usman@example.com',
      'Role': 'Donor',
      'Blood Group': 'O+',
      'Status': 'pending',
      'Joined': '2024-03-10',
    },
    {
      'Name': 'Fatima Malik',
      'Email': 'fatima@example.com',
      'Role': 'Receiver',
      'Blood Group': 'AB+',
      'Status': 'active',
      'Joined': '2024-03-22',
    },
    {
      'Name': 'Bilal Raza',
      'Email': 'bilal@example.com',
      'Role': 'Donor',
      'Blood Group': 'B+',
      'Status': 'active',
      'Joined': '2024-04-01',
    },
    {
      'Name': 'Nadia Siddiqui',
      'Email': 'nadia@example.com',
      'Role': 'Donor',
      'Blood Group': 'O-',
      'Status': 'rejected',
      'Joined': '2024-04-18',
    },
    {
      'Name': 'Hamza Tariq',
      'Email': 'hamza@example.com',
      'Role': 'Receiver',
      'Blood Group': 'A-',
      'Status': 'active',
      'Joined': '2024-05-05',
    },
    {
      'Name': 'Zara Iqbal',
      'Email': 'zara@example.com',
      'Role': 'Donor',
      'Blood Group': 'AB-',
      'Status': 'pending',
      'Joined': '2024-05-20',
    },
    {
      'Name': 'Omar Sheikh',
      'Email': 'omar@example.com',
      'Role': 'Donor',
      'Blood Group': 'A+',
      'Status': 'active',
      'Joined': '2024-06-01',
    },
    {
      'Name': 'Hina Baig',
      'Email': 'hina@example.com',
      'Role': 'Receiver',
      'Blood Group': 'O+',
      'Status': 'active',
      'Joined': '2024-06-15',
    },
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_roleFilter == 'All') return _allUsers;
    return _allUsers.where((u) => u['Role'] == _roleFilter).toList();
  }

  int get _donorCount => _allUsers.where((u) => u['Role'] == 'Donor').length;
  int get _receiverCount =>
      _allUsers.where((u) => u['Role'] == 'Receiver').length;
  int get _activeCount =>
      _allUsers.where((u) => u['Status'] == 'active').length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 16),
          DataTableWidget(
            columns: const ['Name', 'Email', 'Role', 'Blood Group', 'Status', 'Joined'],
            rows: _filteredUsers,
            searchHint: 'Search users by name, email...',
            onEdit: (row) => _showUserDialog(context, row),
            onDelete: (row) => setState(() => _allUsers
                .removeWhere((u) => u['Email'] == row['Email'])),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Manage donors and receivers on the platform',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showUserDialog(context, null),
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCardWidget(
          title: 'Total Users',
          value: '${_allUsers.length}',
          icon: Icons.people,
          color: Colors.blue,
          percentage: '+12%',
        ),
        StatCardWidget(
          title: 'Donors',
          value: '$_donorCount',
          icon: Icons.favorite,
          color: Colors.red,
          percentage: '+8%',
        ),
        StatCardWidget(
          title: 'Receivers',
          value: '$_receiverCount',
          icon: Icons.person_search,
          color: Colors.orange,
          percentage: '+5%',
        ),
        StatCardWidget(
          title: 'Active Users',
          value: '$_activeCount',
          icon: Icons.verified_user,
          color: Colors.green,
          percentage: '+15%',
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: ['All', 'Donor', 'Receiver'].map((filter) {
        final isSelected = _roleFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => _roleFilter = filter),
            selectedColor: Colors.red.shade50,
            checkmarkColor: Colors.red.shade700,
            labelStyle: GoogleFonts.poppins(
              color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showUserDialog(BuildContext context, Map<String, dynamic>? existing) {
    final nameController =
        TextEditingController(text: existing?['Name'] ?? '');
    final emailController =
        TextEditingController(text: existing?['Email'] ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isEdit ? 'Save Changes' : 'Add User'),
          ),
        ],
      ),
    );
  }
}
