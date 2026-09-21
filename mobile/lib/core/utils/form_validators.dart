/// Centralized form validation utilities for Club 100 Gym / Elite Fitness Gym.
/// Ensures production-grade data integrity and consistent user feedback across all forms.
class FormValidators {
  FormValidators._();

  /// Validates a required text field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates full names, gym names, or titles.
  static String? validateName(
    String? value, {
    String fieldName = 'Name',
    int minLength = 2,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validates phone numbers (standard 10-digit Indian phone or international 10-15 digits).
  static String? validatePhone(
    String? value, {
    String fieldName = 'Phone number',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-+()]'), '');
    if (cleanPhone.length < 10) {
      return 'Enter a valid $fieldName (at least 10 digits)';
    }
    if (!RegExp(r'^\d{10,15}$').hasMatch(cleanPhone)) {
      return 'Enter a valid numeric $fieldName';
    }
    return null;
  }

  /// Validates email address (optional or required).
  static String? validateEmail(
    String? value, {
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Email address is required';
      return null;
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates website URL or domain (e.g. `https://elitefitnessgym.com` or `elitefitnessgym.com`).
  static String? validateWebsite(
    String? value, {
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Website URL is required';
      return null;
    }
    final trimmed = value.trim();
    // Allow either with protocol (http/https) or domain format (example.com, www.example.com)
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(trimmed)) {
      return 'Enter a valid website (e.g., gym.com or https://gym.com)';
    }
    return null;
  }

  /// Validates monetary amounts (fees, salaries, payouts).
  static String? validateAmount(
    String? value, {
    String fieldName = 'Amount',
    bool allowZero = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid numeric $fieldName';
    }
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$fieldName cannot be negative'
          : '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates 4-digit or 6-digit MPIN.
  static String? validateMpin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'MPIN is required';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(trimmed)) {
      return 'MPIN must be 4 or 6 numeric digits';
    }
    return null;
  }
}

