import 'package:flutter/services.dart';

/// Input filters shared by all forms. Validation remains authoritative, but
/// these filters prevent obviously unrelated characters while typing.
class AppInputFormatters {
  static final name = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\u0621-\u063A\u0641-\u065F\u066E-\u06D3\u06D5\u06EE-\u06EF\u06FA-\u06FC\u06FF .'-]")),
    LengthLimitingTextInputFormatter(100),
  ];

  static final email = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~@-]")),
    LengthLimitingTextInputFormatter(100),
  ];

  static final phone = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]')),
    LengthLimitingTextInputFormatter(17),
  ];

  static final digits = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final age = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ];

  static final units = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(2),
  ];

  static final cnic = <TextInputFormatter>[_CnicInputFormatter()];

  static final hospitalName = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'[<>\x00-\x1F\x7F-\x9F]')),
    LengthLimitingTextInputFormatter(100),
  ];

  static final address = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'[<>\x00-\x1F\x7F-\x9F]')),
    LengthLimitingTextInputFormatter(300),
  ];

  static final notes = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]')),
    LengthLimitingTextInputFormatter(300),
  ];

  static final subject = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F-\x9F]')),
    LengthLimitingTextInputFormatter(100),
  ];
}

class _CnicInputFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(_nonDigits, '');
    int digitsBefore(int offset) => newValue.text
        .substring(0, offset.clamp(0, newValue.text.length).toInt())
        .replaceAll(_nonDigits, '')
        .length;
    var base = digitsBefore(newValue.selection.baseOffset);
    var extent = digitsBefore(newValue.selection.extentOffset);

    // Deleting a separator also removes the adjacent digit, so backspace
    // does not get stuck on a dash that would immediately be reinserted.
    if (oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        newValue.text.length < oldValue.text.length &&
        digits == oldValue.text.replaceAll(_nonDigits, '')) {
      final backspace = newValue.selection.baseOffset < oldValue.selection.baseOffset;
      final index = backspace ? base - 1 : base;
      if (index >= 0 && index < digits.length) {
        digits = digits.replaceRange(index, index + 1, '');
        if (backspace) base--;
        extent = base;
      }
    }
    if (digits.length > 13) digits = digits.substring(0, 13);
    final formatted = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) formatted.write('-');
      formatted.write(digits[i]);
    }
    final text = formatted.toString();
    int cursorOffset(int count) {
      final digitsCount = count.clamp(0, digits.length).toInt();
      return digitsCount +
          (digitsCount >= 5 && digits.length > 5 ? 1 : 0) +
          (digitsCount >= 12 && digits.length > 12 ? 1 : 0);
    }
    return TextEditingValue(
      text: text,
      selection: newValue.selection.isValid
          ? TextSelection(
              baseOffset: cursorOffset(base),
              extentOffset: cursorOffset(extent),
            )
          : TextSelection.collapsed(offset: text.length),
    );
  }
}
