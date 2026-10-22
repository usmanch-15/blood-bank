import 'package:bloodbank/constants/app_theme.dart';
import 'package:bloodbank/models/awareness_banner.dart';
import 'package:bloodbank/utils/feedback.dart';
import 'package:bloodbank/widgets/awareness_banner_card.dart';
import 'package:bloodbank/widgets/dashboard_components.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                    ).copyWith(textScaler: const TextScaler.linear(1.5)),
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
