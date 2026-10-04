import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../controllers/donor_controller.dart';
import '../../widgets/report_misuse_button.dart';

class BloodRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;

  /// ✅ NEW — Firestore doc id of this blood_requests entry. Needed so the
  /// donor can Accept (confirmDonation Cloud Function requires it) or
  /// Decline (recorded on the donor's own doc) this specific request.
  /// Nullable to stay backward compatible with any other caller that
  /// doesn't have it handy — Accept/Decline are simply hidden if absent.
  final String? requestId;

  const BloodRequestDetailScreen({
    super.key,
    required this.requestData,
    this.requestId,
  });

  @override
  State<BloodRequestDetailScreen> createState() =>
      _BloodRequestDetailScreenState();
}

class _BloodRequestDetailScreenState extends State<BloodRequestDetailScreen> {
  bool _isSubmitting = false;

  Future<void> _handleAccept() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final requestId = widget.requestId;
    if (uid == null || requestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.requestData['status'] == 'accepted' ? 'Confirm Donation' : 'Accept Request'),
        content: Text(widget.requestData['status'] != 'accepted' ? 'Accept this request to arrange a donation. Confirm completion only after donating.' :
          'This marks the request as fulfilled by you and adds it to your '
              'donation history. Only confirm once you\'ve actually donated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.requestData['status'] != 'accepted') {
        await context.read<DonorController>().acceptRequest(requestId);
      } else {
      await context.read<DonorController>().confirmDonation(
        donorId: uid,
        bloodGroup: widget.requestData['bloodGroup'] ?? '',
        requestId: requestId,
      );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.requestData['status'] == 'accepted' ? 'Donation confirmed — thank you!' : 'Request accepted. Confirm after donating.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDecline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final requestId = widget.requestId;
    if (uid == null || requestId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<DonorController>().declineRequest(
        donorId: uid,
        requestId: requestId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not decline: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.requestData;
    final urgency = d['urgency'] ?? 'Normal';
    final status = d['status'] ?? 'pending';

    final urgencyColor = urgency == 'Critical'
        ? Colors.red
        : urgency == 'Urgent'
        ? Colors.orange
        : Colors.green;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Request Details'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Card: Blood Group + Urgency ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Blood Group
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        d['bloodGroup'] ?? '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d['unitsRequired'] ?? d['quantity'] ?? 1} Units Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Urgency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '⚠ $urgency',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Status: $status',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Patient Info ──
            _sectionTitle('Patient Information'),
            _infoCard([
              _infoRow(Icons.person_outline, 'Patient Name',
                  d['patientName'] ?? 'Not provided'),
              _infoRow(Icons.cake_outlined, 'Age',
                  d['patientAge'] != null ? '${d['patientAge']} years' : 'Not provided'),
              _infoRow(Icons.transgender, 'Gender',
                  d['patientGender'] ?? 'Not provided'),
              _infoRow(Icons.info_outline, 'Reason',
                  d['reason'] ?? 'Not provided'),
            ]),

            const SizedBox(height: 16),

            // ── Hospital Info ──
            _sectionTitle('Hospital Information'),
            _infoCard([
              _infoRow(Icons.local_hospital_outlined, 'Hospital',
                  d['hospitalName'] ?? 'Not provided'),
              _infoRow(Icons.location_on_outlined, 'Hospital Address',
                  d['hospitalAddress'] ?? 'Not provided'),
              _infoRow(Icons.location_city_outlined, 'Location',
                  d['location'] ?? 'Not provided'),
            ]),

            const SizedBox(height: 16),

            // ── Request Info ──
            _sectionTitle('Request Information'),
            _infoCard([
              _infoRow(Icons.calendar_today_outlined, 'Required By',
                  d['requiredBy'] != null
                      ? _formatDate(d['requiredBy'])
                      : 'Not specified'),
              _infoRow(Icons.access_time_outlined, 'Requested On',
                  d['createdAt'] != null
                      ? _formatDate(d['createdAt'])
                      : 'Unknown'),
              _infoRow(Icons.person_pin_outlined, 'Requested By',
                  d['requesterName'] ?? 'Unknown'),
            ]),

            const SizedBox(height: 4),
            // ✅ FIX: ReportMisuseButton existed but was never placed on
            // any live screen, so users had no way to actually report a
            // suspicious/fake request. This is the most natural place —
            // a donor reviewing a request they think is fraudulent.
            Align(
              alignment: Alignment.centerRight,
              child: ReportMisuseButton(
                targetUserId: d['requesterId']?.toString(),
                targetRequestId: d['id']?.toString(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Contact Button ──
            if (d['contactNumber'] != null &&
                d['contactNumber'].toString().isNotEmpty) ...[
              _sectionTitle('Contact'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            color: AppColors.primaryRed, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          d['contactNumber'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: d['contactNumber']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Number copied!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(Icons.copy,
                              color: Colors.grey, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.call),
                        label: Text(
                          'Call Now',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // url_launcher se call open kar sakte ho
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Calling ${d['contactNumber']}...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Accept / Decline (only when we know which request this is,
            // and it's still awaiting a donor) ──
            if (widget.requestId != null && (status == 'pending' || (status == 'accepted' && d['acceptedDonorId'] == FirebaseAuth.instance.currentUser?.uid))) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting || status == 'accepted' ? null : _handleDecline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(Icons.check),
                      label: Text(
                        status == 'accepted' ? 'Confirm Donation' : 'Accept',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleAccept,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else {
        dt = date.toDate();
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Unknown';
    }
  }
}