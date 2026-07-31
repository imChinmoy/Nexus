class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit phone';
    return null;
  }

  static String? rollNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Roll number is required';
    if (value.trim().length < 5) return 'Enter a valid roll number';
    return null;
  }

  static String? minLength(String? value, int min, [String? label]) {
    if (value == null || value.trim().length < min) {
      return '${label ?? 'Field'} must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? label]) {
    if (value != null && value.trim().length > max) {
      return '${label ?? 'Field'} must not exceed $max characters';
    }
    return null;
  }
}
