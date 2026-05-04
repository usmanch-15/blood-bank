import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class DonorMatchingScreen extends StatefulWidget {
  final String? requiredBloodGroup;

  const DonorMatchingScreen({super.key, this.requiredBloodGroup});

  @override
  State<DonorMatchingScreen> createState() => _DonorMatchingScreenState();
}

class _DonorMatchingScreenState extends State<DonorMatchingScreen> {
  String _selectedBloodGroup = 'All';
  String _searchQuery = '';

  final List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  final List<_DonorProfile> _donors = [
    _DonorProfile(
      name: 'Ali Hassan',
      bloodGroup: 'O+',
      location: 'Lahore, Punjab',
      distanceKm: 1.2,
      lastDonation: '3 months ago',
      isEligible: true,
      phone: '03001234567',
    ),
    _DonorProfile(
      name: 'Sara Khan',
      bloodGroup: 'A+',
      location: 'Lahore, Gulberg',
      distanceKm: 3.5,
      lastDonation: '6 months ago',
      isEligible: true,
      phone: '03001234568',
    ),
    _DonorProfile(
      name: 'Ahmed Raza',
      bloodGroup: 'B+',
      location: 'Lahore, DHA',
      distanceKm: 5.1,
      lastDonation: '2 months ago',
      isEligible: false,
      phone: '03001234569',
    ),
    _DonorProfile(
      name: 'Fatima Malik',
      bloodGroup: 'AB-',
      location: 'Lahore, Model Town',
      distanceKm: 7.8,
      lastDonation: '5 months ago',
      isEligible: true,
      phone: '03001234570',
    ),
    _DonorProfile(
      name: 'Omar Sheikh',
      bloodGroup: 'O-',
      location: 'Lahore, Johar Town',
      distanceKm: 9.2,
      lastDonation: '4 months ago',
      isEligible: true,
      phone: '03001234571',
    ),
    _DonorProfile(
      name: 'Bilal Tariq',
      bloodGroup: 'A-',
      location: 'Lahore, Iqbal Town',
      distanceKm: 11.0,
      lastDonation: '8 months ago',
      isEligible: true,
      phone: '03001234572',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.requiredBloodGroup != null) {
      _selectedBloodGroup = widget.requiredBloodGroup!;
    }
  }

  List<_DonorProfile> get _filtered {
    return _donors.where((d) {
      final matchGroup =
          _selectedBloodGroup == 'All' || d.bloodGroup == _selectedBloodGroup;
      final matchSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchGroup && matchSearch;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          'Find Donors',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildBloodGroupFilter(),
          _buildResultsSummary(),
          Expanded(child: _buildDonorList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryRed,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or location...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBloodGroupFilter() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _bloodGroups.length,
        itemBuilder: (_, index) {
          final group = _bloodGroups[index];
          final isSelected = _selectedBloodGroup == group;
          return GestureDetector(
            onTap: () => setState(() => _selectedBloodGroup = group),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                group,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsSummary() {
    final eligible = _filtered.where((d) => d.isEligible).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.backgroundLight,
      child: Row(
        children: [
          Text(
            '${_filtered.length} donors found',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$eligible eligible',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No donors found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different blood group or location',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildDonorCard(_filtered[index]),
    );
  }

  Widget _buildDonorCard(_DonorProfile donor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                child: Text(
                  donor.name[0],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: donor.isEligible
                        ? AppColors.success
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    donor.isEligible ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        donor.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _bloodBadge(donor.bloodGroup),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        donor.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${donor.distanceKm} km',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.history,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Last donated: ${donor.lastDonation}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: donor.isEligible
                            ? () => _showContactDialog(donor)
                            : null,
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text(
                          'Contact',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          side: const BorderSide(
                              color: AppColors.primaryRed),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    if (!donor.isEligible) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Not eligible',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloodBadge(String group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        group,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showContactDialog(_DonorProfile donor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.phone, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Text('Contact Donor',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(donor.name,
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(donor.phone,
                style: GoogleFonts.poppins(
                    color: AppColors.primaryRed, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed),
          ),
        ],
      ),
    );
  }
}

class _DonorProfile {
  final String name;
  final String bloodGroup;
  final String location;
  final double distanceKm;
  final String lastDonation;
  final bool isEligible;
  final String phone;

  const _DonorProfile({
    required this.name,
    required this.bloodGroup,
    required this.location,
    required this.distanceKm,
    required this.lastDonation,
    required this.isEligible,
    required this.phone,
  });
}
