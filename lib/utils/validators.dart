class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(value.trim())
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
    final age = int.tryParse(value ?? '');
    return age != null && age >= 1 && age <= 120
        ? null
        : 'Age must be between 1 and 120';
  }

  static String? validateUnitsRequired(String? value) {
    final units = int.tryParse(value ?? '');
    return units != null && units >= 1 && units <= 50
        ? null
        : 'Units must be between 1 and 50';
  }

  static String? validateHospitalName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Hospital name required';
    if (value.trim().length > 100) {
      return 'Hospital name is too long (max 100 chars)';
    }
    if (RegExp(r'[<>\x00-\x1F]').hasMatch(value)) {
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
    return RegExp(r'^\+923[0-9]{9}$').hasMatch(normalizePhone(value))
        ? null
        : 'Enter a Pakistani mobile number (03xx xxxxxxx)';
  }

  static String? validateCnic(String? value) {
    if (value == null ||
        !RegExp(r'^(\d{13}|\d{5}-\d{7}-\d)$').hasMatch(value.trim())) {
      return 'CNIC must be 13 digits (e.g. 12345-1234567-1)';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name required';
    if (value.trim().length < 2) return 'Name too short';
    if (value.trim().length > 100) return 'Name must be at most 100 characters';
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
}
