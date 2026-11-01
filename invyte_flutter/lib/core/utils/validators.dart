abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, [String field = 'This field']) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(value.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Amount']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) return 'Enter a valid ${field.toLowerCase()}';
    return null;
  }

  static String? optionalPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    return number == null || number <= 0 ? 'Enter a whole number' : null;
  }
}
