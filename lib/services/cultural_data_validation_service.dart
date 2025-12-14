/// Service for validating cultural data fields
class CulturalDataValidationService {
  /// Validate nationality field
  static ValidationResult validateNationality(String? nationality) {
    if (nationality == null || nationality.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Nationality is required',
      );
    }

    // Check if nationality contains valid characters
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(nationality.trim())) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Nationality contains invalid characters',
      );
    }

    // Check length
    if (nationality.trim().length < 2) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Nationality must be at least 2 characters',
      );
    }

    if (nationality.trim().length > 50) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Nationality must be less than 50 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate tribe field
  static ValidationResult validateTribe(String? tribe) {
    if (tribe == null || tribe.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Tribe is required',
      );
    }

    // Check if tribe contains valid characters
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(tribe.trim())) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Tribe contains invalid characters',
      );
    }

    // Check length
    if (tribe.trim().length < 2) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Tribe must be at least 2 characters',
      );
    }

    if (tribe.trim().length > 30) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Tribe must be less than 30 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate languages list
  static ValidationResult validateLanguages(List<String>? languages) {
    if (languages == null || languages.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'At least one language is required',
      );
    }

    // Check if any language is empty
    for (String language in languages) {
      if (language.trim().isEmpty) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Language cannot be empty',
        );
      }

      // Check if language contains valid characters
      if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(language.trim())) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Language contains invalid characters: $language',
        );
      }

      // Check length
      if (language.trim().length < 2) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Language must be at least 2 characters: $language',
        );
      }

      if (language.trim().length > 20) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Language must be less than 20 characters: $language',
        );
      }
    }

    // Check for duplicates
    final uniqueLanguages =
        languages.map((e) => e.trim().toLowerCase()).toSet();
    if (uniqueLanguages.length != languages.length) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Duplicate languages are not allowed',
      );
    }

    // Check maximum number of languages
    if (languages.length > 10) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Maximum 10 languages allowed',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate religion field
  static ValidationResult validateReligion(String? religion) {
    if (religion == null || religion.trim().isEmpty) {
      return ValidationResult(
        isValid: true, // Religion is optional
        errorMessage: null,
      );
    }

    // Check if religion contains valid characters
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(religion.trim())) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Religion contains invalid characters',
      );
    }

    // Check length
    if (religion.trim().length < 2) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Religion must be at least 2 characters',
      );
    }

    if (religion.trim().length > 30) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Religion must be less than 30 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate occupation field
  static ValidationResult validateOccupation(String? occupation) {
    if (occupation == null || occupation.trim().isEmpty) {
      return ValidationResult(
        isValid: true, // Occupation is optional
        errorMessage: null,
      );
    }

    // Check if occupation contains valid characters
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(occupation.trim())) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Occupation contains invalid characters',
      );
    }

    // Check length
    if (occupation.trim().length < 2) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Occupation must be at least 2 characters',
      );
    }

    if (occupation.trim().length > 50) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Occupation must be less than 50 characters',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate all cultural fields at once
  static CulturalValidationResult validateAllCulturalFields({
    String? nationality,
    String? tribe,
    List<String>? languages,
    String? religion,
    String? occupation,
  }) {
    final results = <String, ValidationResult>{};

    results['nationality'] = validateNationality(nationality);
    results['tribe'] = validateTribe(tribe);
    results['languages'] = validateLanguages(languages);
    results['religion'] = validateReligion(religion);
    results['occupation'] = validateOccupation(occupation);

    final isValid = results.values.every((result) => result.isValid);
    final errors = results.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => '${entry.key}: ${entry.value.errorMessage}')
        .toList();

    return CulturalValidationResult(
      isValid: isValid,
      errors: errors,
      fieldResults: results,
    );
  }

  /// Sanitize cultural data
  static Map<String, dynamic> sanitizeCulturalData({
    String? nationality,
    String? tribe,
    List<String>? languages,
    String? religion,
    String? occupation,
  }) {
    return {
      'nationality': nationality?.trim() ?? '',
      'tribe': tribe?.trim() ?? '',
      'languages':
          languages?.map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ??
              [],
      'religion': religion?.trim() ?? '',
      'occupation': occupation?.trim() ?? '',
    };
  }

  /// Get common Nigerian tribes for validation
  static List<String> getCommonNigerianTribes() {
    return [
      'Yoruba',
      'Igbo',
      'Hausa',
      'Fulani',
      'Edo',
      'Ijaw',
      'Kanuri',
      'Ibibio',
      'Tiv',
      'Efik',
      'Nupe',
      'Urhobo',
      'Igala',
      'Igbira',
      'Edo',
      'Etsako',
      'Esan',
      'Owan',
      'Akoko-Edo',
      'Other',
    ];
  }

  /// Get common languages for validation
  static List<String> getCommonLanguages() {
    return [
      'English',
      'Yoruba',
      'Igbo',
      'Hausa',
      'French',
      'Portuguese',
      'Spanish',
      'Arabic',
      'Pidgin',
      'Other',
    ];
  }

  /// Get common religions for validation
  static List<String> getCommonReligions() {
    return [
      'Christianity',
      'Islam',
      'Traditional',
      'Atheist',
      'Agnostic',
      'Other',
    ];
  }
}

/// Result of a single field validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Result of cultural fields validation
class CulturalValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, ValidationResult> fieldResults;

  CulturalValidationResult({
    required this.isValid,
    required this.errors,
    required this.fieldResults,
  });

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    final result = fieldResults[fieldName];
    return result?.isValid == false ? result?.errorMessage : null;
  }

  /// Check if a specific field is valid
  bool isFieldValid(String fieldName) {
    final result = fieldResults[fieldName];
    return result?.isValid ?? true;
  }
}
