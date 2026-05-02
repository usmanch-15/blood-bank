import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/blood_request_model.dart';

class DonorMatchingScreen extends StatefulWidget {
  final BloodRequestModel request;

  const DonorMatchingScreen({super.key, required this.request});

  @override
  State<DonorMatchingScreen> createState() => _DonorMatchingScreenState();
}

class _DonorMatchingScreenState extends State<DonorMatchingScreen> {
  bool _isSearching = true;
  String _selectedFilter = 'All';

  // 🔧 Dummy matched donors (replace with Firestore geolocation query)
  final List<Map<String, dynamic>> _matchedDonors = [
    {
      'name': 'Ahmed Raza',
      'bloodGroup': 'O+',
      'distance': '1.2 km',
      'distanceVal': 1.2,
      'location': 'Model Town, Lahore',
      'phone': '03001234567',
      'donations': 8,
      'isEligible': true,
      'lastDonation': '3 months ago',
      'status': 'available',
    },
    {
      'name': 'Sara Khan',
      'bloodGroup': 'O+',
      'distance': '2.5 km',
      'distanceVal': 2.5,
      'location': 'Gulberg, Lahore',
      'phone': '03119876543',
      'donations': 4,
      'isEligible': true,
      'lastDonation': '4 months ago',
      'status': 'available',
    },
    {
      'name': 'Bilal Mahmood',
      'bloodGroup': 'O-',
      'distance': '3.8 km',
      'distanceVal': 3.8,
      'location': 'DHA Phase 5, Lahore',
      'phone': '03334455667',
      'donations': 12,
      'isEligible': true,
      'lastDonation': '5 months ago',
      'status': 'available',
    },
    {
      'name': 'Hina Iqbal',
      'bloodGroup': 'O+',
      'distance': '5.0 km',
      'distanceVal': 5.0,
      'location': 'Johar Town, Lahore',
      'phone': '03211223344',
      'donations': 2,
      'isEligible': false,
      'lastDonation': '1 month ago',
      'status': 'unavailable',
    },
  ];

  final List<String> _filters = ['All', 'Nearest', 'Most Donations', 'Available'];

  @override
  void initState() {
    super.initState();
    _simulateSearch();
  }

  Future<void> _simulateSearch() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isSearching = false);
  }

  List<Map<String, dynamic>> get _filteredDonors {
    List<Map<String, dynamic>> list = List.from(_matchedDonors);
    switch (_selectedFilter) {
      case 'Nearest':
        list.sort((a, b) =>
            (a['distanceVal'] as double).compareTo(b['distanceVal'] as double));
        break;
      case 'Most Donations':
        list.sort(
            (a, b) => (b['donations'] as int).compareTo(a['donations'] as int));
        break;
      case 'Available':
        list = list.where((d) => d['isEligible'] == true).toList();
        break;
    }
    return list;
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'urgent':
        return AppColors.warning;
      default:
        return AppColors.secondaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Matched Donors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isSearching = true);
              _simulateSearch();
            },
          ),
        ],
      ),
      body: _isSearching ? _buildSearchingState() : _buildResults(),
    );
  }

  // ─────────────────────────────────────────────
  // Searching animation state
  // ─────────────────────────────────────────────
  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryRed,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding nearby donors...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Searching for ${widget.request.bloodGroup} donors',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Results
  // ─────────────────────────────────────────────
  Widget _buildResults() {
    final donors = _filteredDonors;
    final availableCount = _matchedDonors.where((d) => d['isEligible'] == true).length;

    return Column(
      children: [
        // Request summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: _urgencyColor(widget.request.urgency).withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.bloodtype,
                color: _urgencyColor(widget.request.urgency),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.request.bloodGroup} • ${widget.request.unitsRequired} units needed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${widget.request.hospitalName} — ${widget.request.urgency.toUpperCase()}',
                      style: TextStyle(
                        color: _urgencyColor(widget.request.urgency),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$availableCount available',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: _filters.map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = f),
                  selectedColor: AppColors.primaryRed.withOpacity(0.15),
                  checkmarkColor: AppColors.primaryRed,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primaryRed
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Donor list
        Expanded(
          child: donors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: donors.length,
                  itemBuilder: (context, index) =>
                      _buildDonorCard(donors[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No eligible donors found nearby',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try expanding your search or use the SOS feature.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(Map<String, dynamic> donor, int index) {
    final isEligible = donor['isEligible'] as bool;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with blood group
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isEligible
                          ? AppColors.primaryRed.withOpacity(0.12)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: isEligible
                            ? AppColors.primaryRed
                            : Colors.grey,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          donor['bloodGroup'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            donor['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isEligible
                                  ? AppColors.success.withOpacity(0.12)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isEligible ? 'Eligible' : 'Not Eligible',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isEligible
                                    ? AppColors.success
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            donor['location'],
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.near_me_outlined,
                              size: 13, color: AppColors.secondaryBlue),
                          const SizedBox(width: 3),
                          Text(
                            donor['distance'],
                            style: const TextStyle(
                              color: AppColors.secondaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.volunteer_activism,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${donor['donations']} donations',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isEligible
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Calling ${donor['name']}...'),
                                backgroundColor: AppColors.secondaryBlue,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryBlue,
                      side: BorderSide(
                          color: isEligible
                              ? AppColors.secondaryBlue
                              : Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isEligible
                        ? () {
                            _showConfirmDialog(donor);
                          }
                        : null,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEligible
                          ? AppColors.primaryRed
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

  void _showConfirmDialog(Map<String, dynamic> donor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Blood Request'),
        content: Text(
          'Send a blood donation request to ${donor['name']}?\n\nThey will receive a notification immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Request sent to ${donor['name']} successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
