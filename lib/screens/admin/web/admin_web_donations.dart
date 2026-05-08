import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/donation_model.dart';
import '../../../constants/app_colors.dart';

class AdminWebDonations extends StatefulWidget {
  const AdminWebDonations({Key? key}) : super(key: key);

  @override
  State<AdminWebDonations> createState() => _AdminWebDonationsState();
}

class _AdminWebDonationsState extends State<AdminWebDonations> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _bloodGroupFilter = 'All';
  String _sortBy = 'Newest First';

  final List<String> _bloodGroups = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  final List<String> _sortOptions = [
    'Newest First', 'Oldest First', 'Most Points'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<DonationModel>> _getDonations() {
    return FirebaseFirestore.instance
        .collection('donations')
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => DonationModel.fromFirestore(
        d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donation Records',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete history of all blood donations',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              _buildSummaryCards(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Filters ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              // Search
              Expanded(
                child: _searchField(),
              ),
              const SizedBox(width: 12),
              // Blood group filter
              _dropdownFilter(
                value: _bloodGroupFilter,
                items: _bloodGroups,
                label: 'Blood Group',
                onChanged: (v) => setState(() => _bloodGroupFilter = v!),
              ),
              const SizedBox(width: 12),
              // Sort
              _dropdownFilter(
                value: _sortBy,
                items: _sortOptions,
                label: 'Sort',
                onChanged: (v) => setState(() => _sortBy = v!),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Table ────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: StreamBuilder<List<DonationModel>>(
              stream: _getDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryRed),
                  );
                }
                if (snapshot.hasError) {
                  return _errorWidget(snapshot.error.toString());
                }

                var donations = snapshot.data ?? [];

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  donations = donations.where((d) {
                    return d.donorName
                        .toLowerCase()
                        .contains(_searchQuery) ||
                        d.bloodGroup
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        d.location
                            .toLowerCase()
                            .contains(_searchQuery);
                  }).toList();
                }

                // Blood group filter
                if (_bloodGroupFilter != 'All') {
                  donations = donations
                      .where((d) => d.bloodGroup == _bloodGroupFilter)
                      .toList();
                }

                // Sort
                switch (_sortBy) {
                  case 'Oldest First':
                    donations.sort(
                            (a, b) => a.donationDate.compareTo(b.donationDate));
                    break;
                  case 'Most Points':
                    donations.sort(
                            (a, b) => b.pointsEarned.compareTo(a.pointsEarned));
                    break;
                  default:
                    donations.sort(
                            (a, b) => b.donationDate.compareTo(a.donationDate));
                }

                if (donations.isEmpty) {
                  return _emptyState();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${donations.length} donation${donations.length == 1 ? '' : 's'} found',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: Colors.grey.shade200),
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
                              headingRowColor:
                              MaterialStateProperty.all(
                                  Colors.grey.shade50),
                              headingTextStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              columnSpacing: 24,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text('Donor')),
                                DataColumn(label: Text('Blood Group')),
                                DataColumn(label: Text('Location')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Points Earned')),
                                DataColumn(label: Text('Health Data')),
                              ],
                              rows: donations
                                  .map((d) => _buildRow(d))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(DonationModel d) {
    return DataRow(cells: [
      // Donor
      DataCell(
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red.shade100,
              child: Text(
                d.donorName.isNotEmpty ? d.donorName[0].toUpperCase() : '?',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Text(d.donorName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),

      // Blood group
      DataCell(
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            d.bloodGroup,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),

      // Location
      DataCell(
        Row(
          children: [
            Icon(Icons.location_on,
                size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                d.location,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      // Date
      DataCell(Text(
        _formatDate(d.donationDate),
        style:
        TextStyle(color: Colors.grey.shade600, fontSize: 12),
      )),

      // Points
      DataCell(
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars,
                  size: 14, color: Colors.amber.shade700),
              const SizedBox(width: 4),
              Text(
                '+${d.pointsEarned}',
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),

      // Health data
      DataCell(
        d.healthCheckData != null && d.healthCheckData!.isNotEmpty
            ? TextButton.icon(
          onPressed: () => _showHealthData(d),
          icon: const Icon(Icons.monitor_heart, size: 16),
          label: const Text('View', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600),
        )
            : Text('—',
            style: TextStyle(color: Colors.grey.shade400)),
      ),
    ]);
  }

  void _showHealthData(DonationModel d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.monitor_heart, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Text('Health Data — ${d.donorName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: d.healthCheckData!.entries
              .map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  '${e.key}: ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600),
                ),
                Text('${e.value}'),
              ],
            ),
          ))
              .toList(),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Summary cards (total donations + unique donors) ──────────
  Widget _buildSummaryCards() {
    return StreamBuilder<List<DonationModel>>(
      stream: _getDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        final uniqueDonors =
            donations.map((d) => d.donorId).toSet().length;
        final totalPoints = donations.fold<int>(
            0, (sum, d) => sum + d.pointsEarned);
        return Row(
          children: [
            _miniCard('Total', '${donations.length}', Icons.favorite,
                Colors.red),
            const SizedBox(width: 12),
            _miniCard('Donors', '$uniqueDonors', Icons.people,
                Colors.blue),
            const SizedBox(width: 12),
            _miniCard(
                'Points Given', '$totalPoints', Icons.stars, Colors.amber),
          ],
        );
      },
    );
  }

  Widget _miniCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
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
          hintText: 'Search by donor name, blood group or location...',
          hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
          Icon(Icons.search, color: Colors.grey.shade400, size: 20),
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
    );
  }

  Widget _dropdownFilter({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
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
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items
              .map((i) => DropdownMenuItem(
            value: i,
            child: Text(i, style: const TextStyle(fontSize: 13)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _errorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Error: $error',
              style: TextStyle(color: Colors.red.shade400)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No donations match your search'
                : 'No donation records yet',
            style:
            TextStyle(fontSize: 16, color: Colors.grey.shade500),
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