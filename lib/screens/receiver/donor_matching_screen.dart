import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../utils/eligibility_checker.dart';
import '../../controllers/donor_controller.dart';

class DonorMatchingScreen extends StatefulWidget {
  final String? initialBloodGroup;

  /// ✅ NEW — when this screen is opened from a specific blood request
  /// (recommended), pass that request's id here. The confirmDonation
  /// Cloud Function requires the caller to be either the donor
  /// themselves or the requester of THIS request, so donations can only
  /// be confirmed here when this is set (or when the donor confirms
  /// their own donation from a different flow).
  final String? requestId;

  const DonorMatchingScreen({
    super.key,
    this.initialBloodGroup,
    this.requestId,
  });

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
      // ✅ FIX: 'role' session ke hisaab se badalta hai — 'isDonor' permanent
      // capability flag use karo. 'isEligible' stored field stale ho sakta
      // hai (sirf donor ke app kholne par update hota hai) is liye query
      // se hata diya — asli eligibility neeche lastDonationDate se
      // real-time compute hoti hai (_filteredDonors mein).
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('isDonor', isEqualTo: true)
          .where('status', isEqualTo: 'approved');

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

  // ✅ CHANGED: phoneNumber used to be read straight off DonorModel
  // (populated from the top-level users/{uid} doc). That doc no longer
  // carries phoneNumber (security fix — it was readable by any signed-in
  // user). The number now lives in users/{uid}/private/contact, which a
  // receiver can't read directly — so this calls the getDonorContact
  // Cloud Function instead, which checks the donor is approved and logs
  // the lookup to audit_logs.
  Future<void> _callDonor(DonorModel donor) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching donor number...'), duration: Duration(seconds: 1)),
    );
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getDonorContact');
      final result = await callable.call({'donorId': donor.uid});
      final phone = result.data['phoneNumber'] as String?;

      if (!mounted) return;
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
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not fetch donor number')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch donor number: $e')),
      );
    }
  }

  // ✅ NEW: pehle app mein donation "complete" mark karne ka koi zariya
  // hi nahi tha — donation record, reward points, certificate, eligibility
  // sab backend mein maujood thay lekin kabhi trigger hi nahi hotay thay.
  Future<void> _confirmDonation(DonorModel donorModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Donation'),
        content: Text(
          'Kya ${donorModel.name} ne aapko ${donorModel.bloodGroup} blood diya hai? '
              'Confirm karne par unko reward points aur donation certificate mil jayega.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirming donation...')),
      );
      await DonorController().confirmDonation(
        donorId: donorModel.uid,
        bloodGroup: donorModel.bloodGroup ?? _selectedBloodGroup ?? '',
        requestId: widget.requestId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation confirmed! Donor has been rewarded. 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      _fetchDonors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to confirm donation: $e'),
            backgroundColor: AppColors.error),
      );
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
                  onCall: () => _callDonor(filtered[i]),
                  // ✅ Only offer "Mark Donation Complete" when opened
                  // with a requestId — confirmDonation (Cloud Function)
                  // requires the caller to be the requester of that
                  // specific request, so without one this would always
                  // fail with permission-denied.
                  onMarkDonated: widget.requestId != null
                      ? () => _confirmDonation(filtered[i])
                      : null,
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
  final VoidCallback? onMarkDonated; // ✅ nullable — hidden when no requestId

  const _DonorCard({
    required this.donor,
    required this.onCall,
    this.onMarkDonated,
  });

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
            // Call + Mark Donated buttons
            if (eligible)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 4),
                  if (onMarkDonated != null)
                    IconButton(
                      onPressed: onMarkDonated,
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppColors.primaryRed),
                      tooltip: 'Mark Donation Complete',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryRed.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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