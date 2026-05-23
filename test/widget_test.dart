import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ✅ FIXED: correct package name (was 'package:shimmer/main.dart' — wrong!)
import 'package:bloodbank/main.dart';
import 'package:bloodbank/utils/eligibility_checker.dart';
import 'package:bloodbank/utils/validators.dart';

void main() {
  // ── EligibilityChecker tests ──────────────────────────────
  group('EligibilityChecker', () {
    test('first-time donor is eligible', () {
      expect(EligibilityChecker.isEligibleForDonation(null), isTrue);
    });

    test('donor who donated 90 days ago is eligible', () {
      final lastDonation = DateTime.now().subtract(const Duration(days: 90));
      expect(EligibilityChecker.isEligibleForDonation(lastDonation), isTrue);
    });

    test('donor who donated 30 days ago is NOT eligible', () {
      final lastDonation = DateTime.now().subtract(const Duration(days: 30));
      expect(EligibilityChecker.isEligibleForDonation(lastDonation), isFalse);
    });

    test('daysUntilEligible returns 0 for first-time donor', () {
      expect(EligibilityChecker.daysUntilEligible(null), equals(0));
    });

    test('daysUntilEligible returns correct remaining days', () {
      final lastDonation = DateTime.now().subtract(const Duration(days: 30));
      final days = EligibilityChecker.daysUntilEligible(lastDonation);
      expect(days, greaterThan(0));
    });
  });

  // ── AppValidators tests ───────────────────────────────────
  group('AppValidators', () {
    // Email
    test('valid email passes', () {
      expect(AppValidators.validateEmail('test@example.com'), isNull);
    });

    test('invalid email fails', () {
      expect(AppValidators.validateEmail('not-an-email'), isNotNull);
    });

    test('empty email fails', () {
      expect(AppValidators.validateEmail(''), isNotNull);
    });

    // Password
    test('password under 8 chars fails', () {
      expect(AppValidators.validatePassword('abc123'), isNotNull);
    });

    test('password 8+ chars passes', () {
      expect(AppValidators.validatePassword('securePass1'), isNull);
    });

    // Blood group
    test('valid blood group passes', () {
      for (final bg in ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']) {
        expect(AppValidators.validateBloodGroup(bg), isNull,
            reason: '$bg should be valid');
      }
    });

    test('invalid blood group fails', () {
      expect(AppValidators.validateBloodGroup('X+'), isNotNull);
    });

    // Phone
    test('valid phone passes', () {
      expect(AppValidators.validatePhone('+923001234567'), isNull);
    });

    test('too short phone fails', () {
      expect(AppValidators.validatePhone('0300'), isNotNull);
    });
  });

  // ── Widget smoke test ─────────────────────────────────────
  // NOTE: BloodBankApp uses Firebase — direct pumpWidget() will crash
  // unless Firebase is mocked. Correct tarika:
  //   1) flutter_test + firebase_core_platform_interface mock setup
  //   2) Ya integration_test package use karein real device par
  // Abhi class reference check karta hai (compile-time safety):
  testWidgets('BloodBankApp class exists and is a Widget', (WidgetTester tester) async {
    // ✅ FIXED: MyApp → BloodBankApp (actual class name in main.dart)
    expect(BloodBankApp, isNotNull);
    expect(const BloodBankApp(), isA<Widget>());
  });
}