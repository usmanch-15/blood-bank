import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bloodbank/l10n/app_localizations.dart';

void main() {
  test('English and Urdu resources expose the shared workflow strings', () {
    final en = AppLocalizations(const Locale('en'));
    final ur = AppLocalizations(const Locale('ur'));
    expect(en.retry, 'Retry');
    expect(en.messageHint, 'Message');
    expect(ur.retry, isNot('Retry'));
    expect(ur.messageHint, isNot('Message'));
    expect(ur.activeAccountRequired, isNotEmpty);
  });

  testWidgets('Urdu locale resolves to RTL direction', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ur'),
        supportedLocales: [Locale('en'), Locale('ur')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SizedBox.shrink(),
      ),
    );
    expect(
      Directionality.of(tester.element(find.byType(SizedBox))),
      TextDirection.rtl,
    );
  });
}
