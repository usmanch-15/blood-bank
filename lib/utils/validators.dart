class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  // ✅ FIX (Issue #9): previously only checked length >= 8, so passwords
  // like "aaaaaaaa" were accepted. Now requires a mix of character types.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 10) return 'Password must be at least 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least 1 lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(value)) {
      return 'Password must contain at least 1 special character (!@#\$%^&* etc.)';
    }
    return null;
  }

  // Also add bounds checks used by the blood request form (Issue #17).
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age required';
    final age = int.tryParse(value);
    if (age == null) return 'Enter a valid age';
    if (age < 1 || age > 120) return 'Age must be between 1 and 120';
    return null;
  }

  static String? validateUnitsRequired(String? value) {
    if (value == null || value.isEmpty) return 'Units required';
    final units = int.tryParse(value);
    if (units == null) return 'Enter a valid number';
    if (units < 1 || units > 50) return 'Units must be between 1 and 50';
    return null;
  }

  static String? validateHospitalName(String? value) {
    if (value == null || value.isEmpty) return 'Hospital name required';
    if (value.length > 100) return 'Hospital name is too long (max 100 chars)';
    final regex = RegExp(r'^[a-zA-Z0-9\s\.,\-&]+$');
    if (!regex.hasMatch(value)) return 'Hospital name has invalid characters';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number required';
    final regex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!regex.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  // ✅ NEW — Pakistani CNIC. Accepts both the formatted
  // "12345-1234567-1" style and a plain 13-digit string, since users tend
  // to type either. Always exactly 13 digits underneath.
  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) return 'CNIC is required';
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 13) {
      return 'CNIC must be 13 digits (e.g. 12345-1234567-1)';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name required';
    if (value.length < 2) return 'Name too short';
    return null;
  }

  static String? validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) return 'Blood group required';
    const valid = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    if (!valid.contains(value)) return 'Select a valid blood group';
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }
}