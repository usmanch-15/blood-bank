import 'package:bloodbank/l10n/app_localizations.dart';
import 'package:bloodbank/screens/communication/voice_call_screen.dart';
import 'package:bloodbank/utils/location_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Pakistan location bounds reject nonfinite and out-of-region pins', () {
    expect(LocationHelper.inPakistan(23.5, 60.8), isTrue);
    expect(LocationHelper.inPakistan(37.1, 77.9), isTrue);
    expect(LocationHelper.inPakistan(23.49, 74), isFalse);
    expect(LocationHelper.inPakistan(31, 77.91), isFalse);
    expect(LocationHelper.inPakistan(double.nan, 74), isFalse);
  });

  testWidgets('denied microphone blocks outgoing call before Firebase or RTC', (
    tester,
  ) async {
    var requests = 0;
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'requestPermissions') {
        requests++;
        return <int, int>{7: 0};
      }
      return 0;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate],
        home: VoiceCallScreen(requestId: 'test', calleeId: 'donor'),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(
      find.text(const AppLocalizations(Locale('en')).microphoneRequired),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
