import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/widgets/custom_text_field.dart';
import 'package:bloodbank/utils/validators.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'profile input validates in $brightness with a small keyboard viewport',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.reset);
        final key = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Form(
                    key: key,
                    child: const Column(
                      children: [
                        CustomTextField(
                          label: 'Full Name',
                          validator: AppValidators.validateName,
                        ),
                        CustomTextField(
                          label: 'Phone Number',
                          enabled: false,
                          helperText: 'Changes require verification',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(key.currentState!.validate(), isFalse);
        await tester.enterText(find.byType(TextFormField).first, 'علی احمد');
        expect(key.currentState!.validate(), isTrue);
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
