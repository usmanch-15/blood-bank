import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/utils/account_policy.dart';
import 'package:bloodbank/utils/validators.dart';
import 'package:bloodbank/utils/location_helper.dart';
import 'package:bloodbank/models/blood_request_model.dart';

void main() {
  test(
    'session policy rejects missing, deleted, suspended and unknown accounts',
    () {
      expect(AccountPolicy.isActive(null), isFalse);
      for (final status in [
        'pending',
        'deleted',
        'suspended',
        'rejected',
        'unknown',
      ]) {
        expect(
          AccountPolicy.isActive({'role': 'donor', 'status': status}),
          isFalse,
        );
      }
      expect(
        AccountPolicy.isActive({'role': 'donor', 'status': 'approved'}),
        isTrue,
      );
      expect(
        AccountPolicy.isActive({'role': 'unknown', 'status': 'approved'}),
        isFalse,
      );
    },
  );
  test('mode switching never grants admin and routing shares one policy', () {
    expect(AccountPolicy.canSwitchMode('donor', 'receiver'), isTrue);
    expect(AccountPolicy.canSwitchMode('receiver', 'donor'), isTrue);
    expect(AccountPolicy.canSwitchMode('donor', 'admin'), isFalse);
    expect(AccountPolicy.canSwitchMode('admin', 'donor'), isFalse);
    expect(AccountPolicy.route({'role': 'admin'}), '/admin/dashboard');
    expect(AccountPolicy.route({'role': 'donor'}), '/role-select');
  });
  test('Pakistani phone formats normalize consistently', () {
    for (final value in [
      '0300 1234567',
      '+92 300-1234567',
      '923001234567',
      '00923001234567',
    ]) {
      expect(AppValidators.normalizePhone(value), '+923001234567');
      expect(AppValidators.validatePhone(value), isNull);
    }
    expect(AppValidators.validatePhone('12345678901'), isNotNull);
  });
  test(
    'Unicode and apostrophes accepted; blank and overlong names rejected',
    () {
      expect(AppValidators.validateHospitalName('شفا ہسپتال'), isNull);
      expect(AppValidators.validateHospitalName("Children's Hospital"), isNull);
      expect(AppValidators.validateHospitalName('<script>'), isNotNull);
      expect(AppValidators.validateName('   '), isNotNull);
      expect(AppValidators.validateName('a' * 101), isNotNull);
    },
  );
  test('location rounding and 15 to 30 km expansion boundaries', () {
    expect(LocationHelper.roundForPrivacy(31.123456), 31.12);
    final distance = LocationHelper.calculateDistance(31, 74, 31.18, 74);
    expect(distance, greaterThan(15));
    expect(distance, lessThan(30));
  });
  test('request model preserves cancellation and quantities', () {
    final request = BloodRequestModel(
      id: 'r',
      requesterId: 'u',
      bloodGroup: 'O+',
      hospitalName: 'Hospital',
      location: 'City',
      quantity: 3,
      createdAt: DateTime(2026),
    );
    expect(request.toFirestore()['quantity'], 3);
    expect(request.copyWith(status: 'cancelled').status, 'cancelled');
    expect(request.status, 'pending');
  });
}
