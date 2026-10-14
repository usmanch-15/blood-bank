import 'package:flutter/material.dart';
import '../requests/request_tracking_screen.dart';
import '../../l10n/app_localizations.dart';

class BloodRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String? requestId;
  const BloodRequestDetailScreen({
    super.key,
    required this.requestData,
    this.requestId,
  });
  @override
  Widget build(BuildContext context) =>
      requestId == null
          ? Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).requestUnavailable),
            ),
            body: Center(
              child: Text(AppLocalizations.of(context).openRequestList),
            ),
          )
          : RequestTrackingScreen(requestId: requestId!);
}
