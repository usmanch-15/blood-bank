class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final email = value;
    if (email.length > 100 || email.indexOf('@') > 64 ||
        email.contains(RegExp(r'[\s\x00-\x1F\x7F]'))) {
      return 'Enter a valid email';
    }
    return RegExp(
      r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
    ).hasMatch(email)
        ? null
        : 'Enter a valid email';
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 10) return 'Password must be at least 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include a number';
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value)) {
      return 'Include a special character';
    }
    return null;
  }

  static String? validateAge(String? value) {
    final age = RegExp(r'^[0-9]+$').hasMatch(value ?? '')
        ? int.tryParse(value!)
        : null;
    return age != null && age >= 1 && age <= 120
        ? null
        : 'Age must be between 1 and 120';
  }

  static String? validateUnitsRequired(String? value) {
    final units = RegExp(r'^[0-9]+$').hasMatch(value ?? '')
        ? int.tryParse(value!)
        : null;
    return units != null && units >= 1 && units <= 50
        ? null
        : 'Units must be between 1 and 50';
  }

  static String? validateHospitalName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Hospital name required';
    if (value.length > 100) {
      return 'Hospital name is too long (max 100 chars)';
    }
    if (value.trim().length < 3 ||
        !RegExp(r'\p{L}', unicode: true).hasMatch(value)) {
      return 'Enter a valid hospital name';
    }
    if (RegExp(r'[<>\x00-\x1F\x7F-\x9F]').hasMatch(value)) {
      return 'Hospital name has invalid characters';
    }
    return null;
  }

  static String normalizePhone(String value) {
    var phone = value.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (phone.startsWith('0092')) phone = '+92${phone.substring(4)}';
    if (phone.startsWith('92')) phone = '+$phone';
    if (phone.startsWith('03')) phone = '+92${phone.substring(1)}';
    return phone;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number required';
    if (value.length > 17 || !RegExp(r'^[0-9+() -]+$').hasMatch(value)) {
      return 'Enter a Pakistani mobile number (03xx xxxxxxx)';
    }
    final phone = value.replaceAll(RegExp(r'[() -]'), '');
    return RegExp(r'^(03[0-9]{9}|\+923[0-9]{9})$').hasMatch(phone)
        ? null
        : 'Enter a Pakistani mobile number (03xx xxxxxxx)';
  }

  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^([0-9]{13}|[0-9]{5}-[0-9]{7}-[0-9])$').hasMatch(value)) {
      return 'CNIC must be 13 digits (e.g. 12345-1234567-1)';
    }
    return null;
  }

  static String? validateName(String? value) {
    final name = value ?? '';
    if (name.trim().isEmpty) return 'Name required';
    if (name.length > 100) return 'Name must be at most 100 characters';
    if (!RegExp(
      r"^[A-Za-z\u0621-\u063A\u0641-\u065F\u066E-\u06D3\u06D5\u06EE-\u06EF\u06FA-\u06FC\u06FF .'-]+$",
    ).hasMatch(name) || !RegExp(
      r'[A-Za-z\u0621-\u063A\u0641-\u064A\u066E-\u066F\u0671-\u06D3\u06D5\u06EE-\u06EF\u06FA-\u06FC\u06FF]',
    ).hasMatch(name)) {
      return 'Enter a valid name using letters and spaces';
    }
    return null;
  }

  static String? validateBloodGroup(String? value) {
    return const [
          'A+',
          'A-',
          'B+',
          'B-',
          'O+',
          'O-',
          'AB+',
          'AB-',
        ].contains(value)
        ? null
        : 'Select a valid blood group';
  }

  static String? validateRequired(String? value, String fieldName) =>
      value == null || value.trim().isEmpty ? '$fieldName is required' : null;

  static String? validateLoginPassword(String? value) =>
      value == null || value.isEmpty ? 'Password required' : null;

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    return value == password ? null : 'Passwords do not match';
  }

  static String? validateSubject(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a subject';
    return value.length > 100 ? 'Subject must be at most 100 characters' : null;
  }

  static String? validateAddress(String? value, {bool required = true}) {
    final address = value ?? '';
    if (address.length > 300) return 'Address is too long (max 300 characters)';
    if (address.trim().isEmpty) return required ? 'Address is required' : null;
    if (address.trim().length < 5) return 'Address must be at least 5 characters';
    if (RegExp(r'[\x00-\x1F\x7F-\x9F<>]').hasMatch(address)) {
      return 'Address contains invalid characters';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    if (value == null) return null;
    return value.length > 300 ? 'Notes are too long (max 300 characters)' : null;
  }
}
