import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class NearestDonorSearchScreen extends StatefulWidget {
  const NearestDonorSearchScreen({super.key});

  @override
  State<NearestDonorSearchScreen> createState() =>
      _NearestDonorSearchScreenState();
}

class _NearestDonorSearchScreenState extends State<NearestDonorSearchScreen> {
  String _selectedBloodGroup = 'O+';
  String _selectedRadius = '10 km';
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  final List<String> _radiusOptions = [
    '5 km', '10 km', '20 km', '50 km',
  ];

  final List<_NearbyDonor> _results = [
    _NearbyDonor(
        name: 'Ali Hassan',
        bloodGroup: 'O+',
        distance: 1.2,
        area: 'Gulberg III'),
    _NearbyDonor(
        name: 'Usman Tariq',
        bloodGroup: 'O+',
        distance: 2.8,
        area: 'Model Town'),
    _NearbyDonor(
        name: 'Hamza Baig',
        bloodGroup: 'O+',
        distance: 4.1,
        area: 'Johar Town'),
    _NearbyDonor(
        name: 'Rida Qureshi',
        bloodGroup: 'O+',
        distance: 7.5,
        area: 'DHA Phase 5'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          'Find Nearest Donor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchPanel(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Criteria',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Group',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primaryRed),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _bloodGroups
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBloodGroup = v ?? 'O+'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Radius',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedRadius,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primaryRed),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _radiusOptions
                          .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r,
                                  style: GoogleFonts.poppins())))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRadius = v ?? '10 km'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _runSearch,
              icon: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isSearching ? 'Searching...' : 'Search Nearby Donors',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSearch() async {
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    final filtered = _results
        .where((d) => d.bloodGroup == _selectedBloodGroup)
        .toList();

    if (filtered.isEmpty) {
      return _buildNoResults();
    }

    return Column(
      children: [
        _buildResultHeader(filtered.length),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) =>
                _buildDonorCard(filtered[index], index + 1),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_searching,
              size: 52,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Search for Donors',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select blood group and radius\nthen tap Search',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No donors found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try increasing the search radius',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primaryRed.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.people, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Text(
            '$count donors found within $_selectedRadius',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorCard(_NearbyDonor donor, int rank) {
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
        children: [
          Stack(
            alignment: Alignment.topRight,
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
              if (rank == 1)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star,
                      color: Colors.white, size: 10),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donor.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      donor.area,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donor.bloodGroup,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.near_me,
                        size: 13, color: AppColors.primaryRed),
                    const SizedBox(width: 4),
                    Text(
                      '${donor.distance} km away',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${donor.name}...'),
                      backgroundColor: AppColors.primaryRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.call, color: AppColors.primaryRed),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NearbyDonor {
  final String name;
  final String bloodGroup;
  final double distance;
  final String area;

  const _NearbyDonor({
    required this.name,
    required this.bloodGroup,
    required this.distance,
    required this.area,
  });
}
