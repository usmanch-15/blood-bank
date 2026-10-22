import 'package:flutter/material.dart';
import '../../widgets/dashboard_components.dart';
import '../requests/request_list_screen.dart';

class BloodRequestsHub extends StatelessWidget {
  final int initialIndex;
  const BloodRequestsHub({super.key, this.initialIndex = 0});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    initialIndex: initialIndex,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          dashboardText(context, 'Blood requests', 'خون کی درخواستیں'),
        ),
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: dashboardText(context, 'For you', 'آپ کے لیے')),
            Tab(text: dashboardText(context, 'Invitations', 'دعوتیں')),
            Tab(text: dashboardText(context, 'My responses', 'میرے جوابات')),
            Tab(text: dashboardText(context, 'Active donation', 'جاری عطیہ')),
          ],
        ),
      ),
      body: const SafeArea(
        child: TabBarView(
          children: [
            RequestListScreen(mode: 'discover', embedded: true),
            RequestListScreen(mode: 'invitations', embedded: true),
            RequestListScreen(mode: 'responses', embedded: true),
            RequestListScreen(mode: 'active', embedded: true),
          ],
        ),
      ),
    ),
  );
}
