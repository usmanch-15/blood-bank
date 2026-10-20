import 'package:flutter/material.dart';
import '../requests/request_list_screen.dart';
import 'donor_dashboard_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/stage_h_design.dart';

class BloodNeededNearYouScreen extends StatelessWidget {
  const BloodNeededNearYouScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).bloodNeededNearYou)),
    body: Column(
      children: [
        Expanded(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: StageHCard(child: PremiumSectionHeader(title: AppLocalizations.of(context).bloodNeededNearYou, subtitle: AppLocalizations.of(context).matchingMedicalNote))),
          const Expanded(child: RequestListScreen(mode: 'discover')),
        ])),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: StageHPrimaryButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonorDashboardScreen(),
                      ),
                    ),
                label: AppLocalizations.of(context).goToDashboard,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
