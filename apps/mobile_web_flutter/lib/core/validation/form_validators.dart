class FormValidators {
  const FormValidators._();

  static String? requiredText(String? value, {required String label}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? requiredTextToken(String? value) {
    return requiredText(value, label: 'Reset token');
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Email is required.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final normalized = value ?? '';
    if (normalized.isEmpty) {
      return 'Password is required.';
    }
    if (normalized.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? securePassword(String? value) {
    final passwordError = password(value);
    if (passwordError != null) {
      return passwordError;
    }

    final normalized = value ?? '';
    if (!normalized.contains(RegExp(r'[A-Za-z]'))) {
      return 'Password must include at least one letter.';
    }
    if (!normalized.contains(RegExp(r'\d'))) {
      return 'Password must include at least one number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, {required String password}) {
    final passwordError = password.isEmpty ? 'Password is required first.' : null;
    if (passwordError != null) {
      return passwordError;
    }
    if ((value ?? '') != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? integer(
    String? value, {
    required String label,
    int? min,
    int? max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$label is required.';
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      return '$label must be a whole number.';
    }
    if (min != null && parsed < min) {
      return '$label must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$label must be at most $max.';
    }
    return null;
  }

  static String? decimal(
    String? value, {
    required String label,
    double? min,
    double? max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$label is required.';
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return '$label must be a number.';
    }
    if (min != null && parsed < min) {
      return '$label must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$label must be at most $max.';
    }
    return null;
  }

  static String? optionalInteger(
    String? value, {
    required String label,
    int? min,
    int? max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      return '$label must be a whole number.';
    }
    if (min != null && parsed < min) {
      return '$label must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$label must be at most $max.';
    }
    return null;
  }

  static String? optionalDecimal(
    String? value, {
    required String label,
    double? min,
    double? max,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return '$label must be a number.';
    }
    if (min != null && parsed < min) {
      return '$label must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$label must be at most $max.';
    }
    return null;
  }
}
