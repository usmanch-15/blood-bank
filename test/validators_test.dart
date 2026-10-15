import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbank/utils/validators.dart';

void main() {
  test('required text rejects null, empty, and whitespace-only values', () {
    expect(AppValidators.validateRequired(null, 'Name'), isNotNull);
    expect(AppValidators.validateRequired('', 'Name'), isNotNull);
    expect(AppValidators.validateRequired('   ', 'Name'), isNotNull);
    expect(AppValidators.validateRequired(' Ali ', 'Name'), isNull);
  });

  test('name validation rejects digits and unrelated punctuation', () {
    expect(AppValidators.validateName('Ali Ahmed'), isNull);
    expect(AppValidators.validateName('علی احمد'), isNull);
    expect(AppValidators.validateName('Ali123'), isNotNull);
    expect(AppValidators.validateName('Ali<script>'), isNotNull);
  });

  test('numeric and phone validators reject malformed values', () {
    expect(AppValidators.validateAge('abc'), isNotNull);
    expect(AppValidators.validateAge('121'), isNotNull);
    expect(AppValidators.validateUnitsRequired('0'), isNotNull);
    expect(AppValidators.validatePhone('03abc'), isNotNull);
    expect(AppValidators.validatePhone('03001234567'), isNull);
  });
}
