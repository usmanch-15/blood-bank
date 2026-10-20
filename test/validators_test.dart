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

  test('email, hospital, address, and notes limits are enforced', () {
    expect(AppValidators.validateEmail('a b@example.com'), isNotNull);
    expect(AppValidators.validateEmail('a@example.com'), isNull);
    expect(AppValidators.validateHospitalName('AB'), isNotNull);
    expect(AppValidators.validateHospitalName('City Hospital'), isNull);
    expect(AppValidators.validateAddress('abc'), isNotNull);
    expect(AppValidators.validateAddress('Main Road 5'), isNull);
    expect(AppValidators.validateNotes(''), isNull);
    expect(AppValidators.validateNotes('x' * 301), isNotNull);
  });

  test('names allow English and Urdu letters with name punctuation only', () {
    for (final value in ["O'Neil", 'Ali-Ahmed', 'A. Khan', 'علی احمد', 'A']) {
      expect(AppValidators.validateName(value), isNull, reason: value);
    }
    for (final value in [
      'Ali1',
      'علی۱',
      'علی١',
      'علی،',
      'Ali\nAhmed',
      'Ali\t',
      '---',
    ]) {
      expect(AppValidators.validateName(value), isNotNull, reason: value);
    }
    expect(AppValidators.validateName(null), isNotNull);
    expect(AppValidators.validateName('a' * 100), isNull);
    expect(AppValidators.validateName('a' * 101), isNotNull);
  });

  test('emails reject whitespace and malformed local or domain parts', () {
    expect(AppValidators.validateEmail('ali.khan+donor@example.com'), isNull);
    expect(AppValidators.validateEmail('${'a' * 60}@${'b' * 35}.com'), isNull);
    expect(
      AppValidators.validateEmail('${'a' * 61}@${'b' * 35}.com'),
      isNotNull,
    );
    expect(AppValidators.validateEmail('${'a' * 65}@example.com'), isNotNull);
    for (final value in [
      null,
      '',
      ' a@example.com',
      'a@example.com ',
      'a\t@example.com',
      'a..b@example.com',
      '.a@example.com',
      'a@-example.com',
      'a@example',
      'a@@example.com',
      'a@exa_mple.com',
      'a<@example.com',
    ]) {
      expect(AppValidators.validateEmail(value), isNotNull, reason: '$value');
    }
  });

  test('Pakistani mobile validation accepts only local and +92 prefixes', () {
    for (final value in [
      '03001234567',
      '0300 1234567',
      '+923001234567',
      '+92 (300) 1234567',
      '03(00)-1234567',
    ]) {
      expect(AppValidators.validatePhone(value), isNull, reason: value);
      expect(AppValidators.normalizePhone(value), '+923001234567');
    }
    for (final value in [
      null,
      '',
      '923001234567',
      '00923001234567',
      '02112345678',
      '+913001234567',
      '0300123456',
      '030012345678',
      '0300\t1234567',
      '0300abc1234567',
      '++923001234567',
      '0300       1234567 ',
    ]) {
      expect(AppValidators.validatePhone(value), isNotNull, reason: '$value');
    }
  });

  test('age and blood units enforce numeric syntax and range boundaries', () {
    for (final value in ['1', '120']) {
      expect(AppValidators.validateAge(value), isNull);
    }
    for (final value in ['1', '50']) {
      expect(AppValidators.validateUnitsRequired(value), isNull);
    }
    for (final value in [null, '', '0', '-1', '+1', '1.0', '1e1', ' 1', '۱']) {
      expect(AppValidators.validateAge(value), isNotNull, reason: '$value');
      expect(
        AppValidators.validateUnitsRequired(value),
        isNotNull,
        reason: '$value',
      );
    }
    expect(AppValidators.validateAge('121'), isNotNull);
    expect(AppValidators.validateUnitsRequired('51'), isNotNull);
  });

  test('CNIC is optional and accepts only 13 digits with standard dashes', () {
    for (final value in [null, '', ' ', '1234512345671', '12345-1234567-1']) {
      expect(AppValidators.validateCnic(value), isNull);
    }
    for (final value in [
      '123451234567',
      '12345123456712',
      '1234-12345678-1',
      '12345 1234567 1',
      '12345-1234567-A',
      '۱۲۳۴۵۱۲۳۴۵۶۷۱',
    ]) {
      expect(AppValidators.validateCnic(value), isNotNull, reason: value);
    }
  });

  test(
    'hospital names require a letter and exclude controls and angle brackets',
    () {
      for (final value in ['ABC', 'شفا ہسپتال', 'Hospital 123', 'a' * 100]) {
        expect(AppValidators.validateHospitalName(value), isNull);
      }
      for (final value in [
        null,
        '',
        'AB',
        '123',
        '۱۲۳',
        '<Hospital>',
        'Hospital\nName',
        'Hospital\u007f',
        'Hospital\u0085',
        'a' * 101,
      ]) {
        expect(
          AppValidators.validateHospitalName(value),
          isNotNull,
          reason: '$value',
        );
      }
    },
  );

  test('addresses and optional notes enforce their length limits', () {
    expect(AppValidators.validateAddress(null), isNotNull);
    expect(AppValidators.validateAddress('', required: false), isNull);
    expect(AppValidators.validateAddress('1234'), isNotNull);
    expect(AppValidators.validateAddress('12345'), isNull);
    expect(AppValidators.validateAddress('a' * 300), isNull);
    expect(AppValidators.validateAddress('a' * 301), isNotNull);
    expect(AppValidators.validateNotes(null), isNull);
    expect(AppValidators.validateNotes(''), isNull);
    expect(AppValidators.validateNotes('a' * 300), isNull);
    expect(AppValidators.validateNotes('a' * 301), isNotNull);
    expect(AppValidators.validateNotes(' ' * 301), isNotNull);
  });

  test(
    'signup keeps its strong password policy and confirms the exact password',
    () {
      expect(AppValidators.validatePassword('StrongPass1!'), isNull);
      for (final value in [
        null,
        '',
        'Short1!',
        'lowercase1!',
        'UPPERCASE1!',
        'NoNumbers!!',
        'NoSymbols123',
      ]) {
        expect(
          AppValidators.validatePassword(value),
          isNotNull,
          reason: '$value',
        );
      }
      expect(
        AppValidators.validateConfirmPassword('StrongPass1!', 'StrongPass1!'),
        isNull,
      );
      expect(
        AppValidators.validateConfirmPassword(null, 'StrongPass1!'),
        isNotNull,
      );
      expect(
        AppValidators.validateConfirmPassword('', 'StrongPass1!'),
        isNotNull,
      );
      expect(
        AppValidators.validateConfirmPassword('StrongPass2!', 'StrongPass1!'),
        isNotNull,
      );
      expect(
        AppValidators.validateConfirmPassword('StrongPass1! ', 'StrongPass1!'),
        isNotNull,
      );
    },
  );

  test(
    'login passwords are required without imposing signup strength rules',
    () {
      expect(AppValidators.validateLoginPassword(null), isNotNull);
      expect(AppValidators.validateLoginPassword(''), isNotNull);
      expect(AppValidators.validateLoginPassword('old'), isNull);
      expect(AppValidators.validateLoginPassword('123'), isNull);
      expect(AppValidators.validateLoginPassword(' '), isNull);
    },
  );

  test('support subjects remain required with a 100-character limit', () {
    expect(AppValidators.validateSubject(null), isNotNull);
    expect(AppValidators.validateSubject(' '), isNotNull);
    expect(AppValidators.validateSubject('a' * 100), isNull);
    expect(AppValidators.validateSubject('a' * 101), isNotNull);
  });
}
