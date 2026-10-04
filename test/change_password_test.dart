import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/widgets/change_password_form.dart';

void main() {
  testWidgets(
    'password form rejects mismatch, toggles visibility and reports save failure',
    (tester) async {
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangePasswordForm(
              onSave: (current, next) async {
                saves++;
                expect(current, 'old password');
                expect(next, 'SecurePass1!');
                throw StateError('Service unavailable');
              },
            ),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'old password');
      await tester.enterText(fields.at(1), 'SecurePass1!');
      await tester.enterText(fields.at(2), 'mismatch');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(saves, 0);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);
      await tester.enterText(fields.at(2), 'SecurePass1!');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.text('Service unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
