import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../widgets/report_misuse_button.dart';

class BloodRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const BloodRequestDetailScreen({super.key, required this.requestData});

  @override
  Widget build(BuildContext context) {
    final d = requestData;
    final urgency = d['urgency'] ?? 'Normal';
    final status = d['status'] ?? 'pending';

    final urgencyColor = urgency == 'Critical'
        ? Colors.red
        : urgency == 'Urgent'
        ? Colors.orange
        : Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Request Details'),
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
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        d['bloodGroup'] ?? '?',
                        style: const TextStyle(
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
                          style: const TextStyle(
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
                            color: urgencyColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Text(
                            '⚠ $urgency',
                            style: const TextStyle(
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
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Status: $status',
                            style: const TextStyle(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            color: AppColors.primaryRed, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          d['contactNumber'],
                          style: const TextStyle(
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
                          child: const Icon(Icons.copy,
                              color: Colors.grey, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text(
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
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