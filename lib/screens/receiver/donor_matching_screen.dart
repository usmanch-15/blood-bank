import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../utils/eligibility_checker.dart';

class DonorMatchingScreen extends StatefulWidget {
  final String? initialBloodGroup;

  const DonorMatchingScreen({super.key, this.initialBloodGroup});

  @override
  State<DonorMatchingScreen> createState() => _DonorMatchingScreenState();
}

class _DonorMatchingScreenState extends State<DonorMatchingScreen> {
  String? _selectedBloodGroup;
  bool _eligibleOnly = true;
  bool _isLoading = false;
  List<DonorModel> _donors = [];
  String _searchQuery = '';

  // Compatible blood groups map
  static const _compatibleGroups = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };

  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _selectedBloodGroup = widget.initialBloodGroup;
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .where('status', isEqualTo: 'approved')
          .where('isEligible', isEqualTo: true);

      final snap = await query.get();
      final donors = snap.docs
          .map((d) =>
          DonorModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();

      setState(() {
        _donors = donors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading donors: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<DonorModel> get _filteredDonors {
    return _donors.where((donor) {
      // Blood group compatibility filter
      if (_selectedBloodGroup != null) {
        final compatible = _compatibleGroups[_selectedBloodGroup] ?? [];
        if (!compatible.contains(donor.bloodGroup)) return false;
      }

      // Eligibility filter
      if (_eligibleOnly) {
        final eligible =
        EligibilityChecker.isEligibleForDonation(donor.lastDonationDate);
        if (!eligible) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = donor.name.toLowerCase();
        final location = (donor.location ?? '').toLowerCase();
        if (!name.contains(query) && !location.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _callDonor(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDonors;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Find Donors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDonors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primaryRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: AppColors.primaryRed),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Blood group dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: 'I need (blood group)',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Any', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Any')),
                          ..._bloodGroups.map((bg) => DropdownMenuItem(
                            value: bg,
                            child: Text(bg),
                          )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedBloodGroup = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Eligible only toggle
                    Column(
                      children: [
                        const Text('Eligible\nonly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Switch(
                          value: _eligibleOnly,
                          activeColor: AppColors.primaryRed,
                          onChanged: (v) => setState(() => _eligibleOnly = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Results count ──
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} donor${filtered.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                if (_selectedBloodGroup != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Compatible with $_selectedBloodGroup',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primaryRed),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Donor List ──
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryRed))
                : filtered.isEmpty
                ? _EmptyState(
              bloodGroup: _selectedBloodGroup,
              onClear: () => setState(() {
                _selectedBloodGroup = null;
                _eligibleOnly = false;
                _searchQuery = '';
              }),
            )
                : RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: _fetchDonors,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _DonorCard(
                  donor: filtered[i],
                  onCall: () =>
                      _callDonor(filtered[i].phoneNumber),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donor Card ────────────────────────────────────────────────
class _DonorCard extends StatelessWidget {
  final DonorModel donor;
  final VoidCallback onCall;

  const _DonorCard({required this.donor, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final eligible =
    EligibilityChecker.isEligibleForDonation(donor.lastDonationDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Blood group badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  donor.bloodGroup ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (donor.location != null && donor.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            donor.location!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: eligible
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          eligible ? 'Eligible' : 'Not Eligible',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: eligible
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${donor.rewardPoints} pts',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Call button
            if (eligible)
              IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.phone, color: AppColors.success),
                tooltip: 'Call Donor',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? bloodGroup;
  final VoidCallback onClear;

  const _EmptyState({this.bloodGroup, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bloodtype, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              bloodGroup != null
                  ? 'No eligible donors found for $bloodGroup'
                  : 'No donors found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing the blood group filter or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off,
                  color: AppColors.primaryRed),
              label: const Text('Clear Filters',
                  style: TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        ),
      ),
    );
  }
}