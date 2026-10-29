import 'package:bloodbank/constants/app_theme.dart';
import 'package:bloodbank/models/awareness_banner.dart';
import 'package:bloodbank/utils/feedback.dart';
import 'package:bloodbank/widgets/awareness_banner_card.dart';
import 'package:bloodbank/widgets/dashboard_components.dart';
import 'package:bloodbank/widgets/custom_button.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared buttons grow for long labels at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final variant in ButtonVariant.values)
                    CustomButton(
                      text: 'Confirm this donation request',
                      variant: variant,
                      size: ButtonSize.small,
                      onPressed: () => taps++,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Confirm this donation request').first);
    expect(taps, 1);
  });
  test('loaded campaigns stop displaying at their scheduled end', () {
    final banner = AwarenessBanner.fromMap({
      'id': 'scheduled',
      'startAt': 100,
      'endAt': 200,
    });
    expect(banner.visibleAt(DateTime.fromMillisecondsSinceEpoch(99)), isFalse);
    expect(banner.visibleAt(DateTime.fromMillisecondsSinceEpoch(100)), isTrue);
    expect(banner.visibleAt(DateTime.fromMillisecondsSinceEpoch(199)), isTrue);
    expect(banner.visibleAt(DateTime.fromMillisecondsSinceEpoch(200)), isFalse);
    expect(
      AwarenessBanner.fromMap({
        'id': 'missing-schedule',
      }).visibleAt(DateTime.now()),
      isFalse,
    );
  });
  test('technical function failures do not expose stack traces', () {
    final error = FirebaseException(
      plugin: 'cloud_functions',
      code: 'not-found',
      message: 'NOT_FOUND\n#0 package:cloud_functions/internal.dart',
    );
    expect(AppFeedback.message(error), isNot(contains('package:')));
    expect(AppFeedback.message(error), contains('unavailable'));
  });
  for (final dark in [false, true]) {
    for (final locale in ['en', 'ur']) {
      testWidgets(
        'request and banner cards fit narrow $locale / dark=$dark with large text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var dismissed = false;
          var opened = false;
          final banner = AwarenessBanner.fromMap({
            'id': 'test',
            'en': {
              'title': 'Help someone nearby',
              'description': 'Keep your availability up to date.',
              'button': 'Explore',
            },
            'ur': {
              'title': 'اپنے قریب کسی کی مدد کریں',
              'description': 'اپنی دستیابی تازہ رکھیں۔',
              'button': 'دیکھیں',
            },
          });
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: const [Locale('en'), Locale('ur')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder:
                  (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        AwarenessBannerCard(
                          banner: banner,
                          onDismiss: () => dismissed = true,
                          onAction: () => opened = true,
                        ),
                        OpportunityCard(
                          data: {
                            'bloodGroup': 'AB+',
                            'hospitalName':
                                'A long hospital name for a narrow screen',
                            'urgency': 'critical',
                            'remainingUnits': 2,
                            'distanceKm': 4.3,
                          },
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(locale == 'ur' ? 'دیکھیں' : 'Explore'));
          expect(opened, isTrue);
          await tester.tap(find.byIcon(Icons.close));
          expect(dismissed, isTrue);
        },
      );
    }
  }
}
