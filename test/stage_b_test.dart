import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/widgets/donor_feed_widgets.dart';

void main() {
  testWidgets('donor feed states loading empty error retry', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DonorFeedStateView(loading: true)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: DonorFeedStateView(loading: false)),
    );
    expect(find.text('No blood requests nearby.'), findsOneWidget);
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DonorFeedStateView(
          loading: false,
          error: 'x',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('donor marker falls back to blood group letters', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DonorMarkerAvatar(bloodGroup: 'O+')),
    );
    expect(find.text('O+'), findsOneWidget);
  });
}
