import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/chart_widget.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebAnalytics extends StatefulWidget {
  const AdminWebAnalytics({Key? key}) : super(key: key);

  @override
  State<AdminWebAnalytics> createState() => _AdminWebAnalyticsState();
}

class _AdminWebAnalyticsState extends State<AdminWebAnalytics> {
  ChartType _donationChartType = ChartType.line;
  ChartType _requestChartType = ChartType.bar;
  String _selectedPeriod = 'Monthly';

  final List<ChartData> _donationData = [
    ChartData('Jan', 45),
    ChartData('Feb', 60),
    ChartData('Mar', 75),
    ChartData('Apr', 88),
    ChartData('May', 102),
    ChartData('Jun', 95),
    ChartData('Jul', 118),
    ChartData('Aug', 125),
    ChartData('Sep', 140),
    ChartData('Oct', 155),
    ChartData('Nov', 170),
    ChartData('Dec', 190),
  ];

  final List<ChartData> _requestsByBloodGroup = [
    ChartData('A+', 120),
    ChartData('A-', 45),
    ChartData('B+', 98),
    ChartData('B-', 32),
    ChartData('O+', 160),
    ChartData('O-', 55),
    ChartData('AB+', 28),
    ChartData('AB-', 15),
  ];

  final List<ChartData> _userRoleData = [
    ChartData('Donors', 720),
    ChartData('Receivers', 514),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildKpiCards(),
          const SizedBox(height: 24),
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildDonationTrendChart()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildUserRoleChart()),
            ],
          ),
          const SizedBox(height: 24),
          _buildBloodGroupRequestsChart(),
          const SizedBox(height: 24),
          _buildSummaryTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          'Platform performance insights and trends',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        StatCardWidget(
          title: 'Total Donations',
          value: '1,363',
          icon: Icons.favorite,
          color: Colors.red,
          percentage: '+18%',
        ),
        StatCardWidget(
          title: 'Fulfillment Rate',
          value: '87%',
          icon: Icons.check_circle,
          color: Colors.green,
          percentage: '+3%',
        ),
        StatCardWidget(
          title: 'Avg. Response Time',
          value: '4.2h',
          icon: Icons.timer,
          color: Colors.blue,
          percentage: '-12%',
          isIncrease: false,
        ),
        StatCardWidget(
          title: 'Active Drives',
          value: '12',
          icon: Icons.event,
          color: Colors.purple,
          percentage: '+25%',
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['Weekly', 'Monthly', 'Quarterly', 'Yearly'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(period),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedPeriod = period),
            selectedColor: Colors.red.shade50,
            labelStyle: GoogleFonts.poppins(
              color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonationTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Donation Trends',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            DropdownButton<ChartType>(
              value: _donationChartType,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                    value: ChartType.line, child: Text('Line')),
                DropdownMenuItem(
                    value: ChartType.bar, child: Text('Bar')),
              ],
              onChanged: (v) =>
                  setState(() => _donationChartType = v ?? ChartType.line),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: ChartWidget(
            title: '',
            data: _donationData,
            type: _donationChartType,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRoleChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Distribution',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: ChartWidget(
            title: '',
            data: _userRoleData,
            type: ChartType.pie,
          ),
        ),
        const SizedBox(height: 12),
        ..._userRoleData.map((d) {
          final color = d.label == 'Donors'
              ? Colors.red.shade400
              : Colors.blue.shade400;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${d.label}: ${d.value}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBloodGroupRequestsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Requests by Blood Group',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            DropdownButton<ChartType>(
              value: _requestChartType,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                    value: ChartType.bar, child: Text('Bar')),
                DropdownMenuItem(
                    value: ChartType.line, child: Text('Line')),
              ],
              onChanged: (v) =>
                  setState(() => _requestChartType = v ?? ChartType.bar),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ChartWidget(
            title: '',
            data: _requestsByBloodGroup,
            type: _requestChartType,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable() {
    final rows = [
      ['A+', '120', '108', '90%'],
      ['B+', '98', '82', '84%'],
      ['O+', '160', '145', '91%'],
      ['AB+', '28', '22', '79%'],
      ['A-', '45', '38', '84%'],
      ['B-', '32', '25', '78%'],
      ['O-', '55', '50', '91%'],
      ['AB-', '15', '11', '73%'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Blood Group Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(Colors.grey.shade50),
              columns: ['Blood Group', 'Requests', 'Fulfilled', 'Rate']
                  .map(
                    (col) => DataColumn(
                      label: Text(
                        col,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: row
                          .map((cell) => DataCell(Text(
                                cell,
                                style: GoogleFonts.poppins(fontSize: 13),
                              )))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
