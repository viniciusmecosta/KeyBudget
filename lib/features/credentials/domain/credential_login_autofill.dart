class CredentialLoginAutofill {
  static String? email(String input) {
    final value = input.trim();
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return value;
    }
    return null;
  }

  static String? phone(String input) {
    final value = input.trim();
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 && digits.length != 11) {
      return null;
    }
    if (RegExp(r'^\(\d{2}\)\s?\d{4,5}-\d{4}$').hasMatch(value) ||
        RegExp(r'^\d{2}\s+\d{4,5}-\d{4}$').hasMatch(value)) {
      return digits;
    }
    return null;
  }
}
