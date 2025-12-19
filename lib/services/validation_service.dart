import 'dart:async';

/// Service for handling input validation
class ValidationService {
  factory ValidationService() => _instance;
  ValidationService._internal();
  static final ValidationService _instance = ValidationService._internal();

  // Profanity filter - basic implementation
  static const List<String> _profanityWords = [
    'badword1', 'badword2', 'badword3', // Add actual profanity words
    'spam', 'scam', 'fake', 'bot',
  ];

  /// Validate group name
  static String? validateGroupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < 3) {
      return 'Group name must be at least 3 characters';
    }

    if (trimmedValue.length > 50) {
      return 'Group name must be less than 50 characters';
    }

    if (_containsProfanity(trimmedValue)) {
      return 'Group name contains inappropriate content';
    }

    if (_containsSpecialCharacters(trimmedValue)) {
      return 'Group name contains invalid characters';
    }

    return null;
  }

  /// Validate group description
  static String? validateGroupDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < 10) {
      return 'Description must be at least 10 characters';
    }

    if (trimmedValue.length > 500) {
      return 'Description must be less than 500 characters';
    }

    if (_containsProfanity(trimmedValue)) {
      return 'Description contains inappropriate content';
    }

    return null;
  }

  /// Validate tag
  static String? validateTag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tag cannot be empty';
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Tag must be at least 2 characters';
    }

    if (trimmedValue.length > 20) {
      return 'Tag must be less than 20 characters';
    }

    if (_containsProfanity(trimmedValue)) {
      return 'Tag contains inappropriate content';
    }

    if (_containsSpecialCharacters(trimmedValue)) {
      return 'Tag contains invalid characters';
    }

    return null;
  }

  /// Validate location
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Location is optional
    }

    final String trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Location must be at least 2 characters';
    }

    if (trimmedValue.length > 100) {
      return 'Location must be less than 100 characters';
    }

    if (_containsProfanity(trimmedValue)) {
      return 'Location contains inappropriate content';
    }

    return null;
  }

  /// Validate max members
  static String? validateMaxMembers(int? value) {
    if (value == null) {
      return 'Max members is required';
    }

    if (value < 2) {
      return 'Group must have at least 2 members';
    }

    if (value > 1000) {
      return 'Group cannot have more than 1000 members';
    }

    return null;
  }

  /// Check if text contains profanity
  static bool _containsProfanity(String text) {
    final String lowerText = text.toLowerCase();
    return _profanityWords
        .any((word) => lowerText.contains(word.toLowerCase()));
  }

  /// Check if text contains special characters
  static bool _containsSpecialCharacters(String text) {
    // Allow letters, numbers, spaces, hyphens, and apostrophes
    final RegExp validCharacters = RegExp(r'^[a-zA-Z0-9\s\-]+$');
    return !validCharacters.hasMatch(text);
  }

  /// Sanitize text input
  static String sanitizeText(String text) {
    return text
        .trim()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Replace multiple spaces with single space
        .replaceAll(
          RegExp(r'[^\w\s\-]'),
          '',
        ); // Remove special characters except allowed ones
  }

  /// Check if group name is available (placeholder for future implementation)
  static Future<bool> isGroupNameAvailable(String groupName) async {
    // TODO: Implement actual check against Firestore
    // For now, return true (available)
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return true;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final String trimmedValue = value.trim();
    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate phone number format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final String trimmedValue = value.trim();
    final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

    if (!phoneRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp('[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp('[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Get password strength score
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[a-z]').hasMatch(password)) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return score;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      case 6:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
}
