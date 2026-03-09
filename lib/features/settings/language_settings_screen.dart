import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const Color primaryColor = AppColors.primaryGreen;
  static const Color cardColor = AppColors.cardColor;
  static const Color successColor = Color(0xFF4CAF50);
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textLight = Color(0xFF999999);

  String _selectedLanguage = 'en';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
      'isAvailable': true,
    },
    {
      'code': 'yo',
      'name': 'Yoruba',
      'nativeName': 'Yorùbá',
      'flag': '🇳🇬',
      'isAvailable': true,
    },
    {
      'code': 'ig',
      'name': 'Igbo',
      'nativeName': 'Igbo',
      'flag': '🇳🇬',
      'isAvailable': true,
    },
    {
      'code': 'ha',
      'name': 'Hausa',
      'nativeName': 'Hausa',
      'flag': '🇳🇬',
      'isAvailable': true,
    },
    {
      'code': 'fr',
      'name': 'French',
      'nativeName': 'Français',
      'flag': '🇫🇷',
      'isAvailable': false, // Coming soon
    },
    {
      'code': 'ar',
      'name': 'Arabic',
      'nativeName': 'العربية',
      'flag': '🇸🇦',
      'isAvailable': false, // Coming soon
    },
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentLanguage());
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selected_language') ?? 'en';

      setState(() {
        _selectedLanguage = savedLanguage;
        _isLoading = false;
      });
    } on Object catch (e) {
      log('Error loading language preference: $e');
      setState(() {
        _selectedLanguage = 'en';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (_isSaving || languageCode == _selectedLanguage) return;

    setState(() => _isSaving = true);

    try {
      // Save language preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);

      // Update UI
      setState(() {
        _selectedLanguage = languageCode;
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
        final language =
            _languages.firstWhere((lang) => lang['code'] == languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed to ${language['name']}',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
        );
      }

      // Note: In a full implementation, you would trigger app-wide language change here
      // For now, we'll show a restart dialog
      _showRestartDialog();
    } on Object catch (e) {
      log('Error changing language: $e');
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to change language',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
        );
      }
    }
  }

  void _showRestartDialog() {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: cardColor,
            shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.chipRadius)),
          elevation: 8,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.language, color: primaryColor, size: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Language Changed',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The language has been changed successfully. Please restart the app to see the changes take effect.',
                style: GoogleFonts.montserrat(
                  color: textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.buttonRadius),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Full localization support is coming soon!',
                        style: GoogleFonts.montserrat(
                          color: primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.buttonRadius),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Language Settings',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const AppLoadingView()
            : SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // Available Languages
                    _buildAvailableLanguagesSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // Coming Soon Languages
                    _buildComingSoonLanguagesSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // Language Info
                    _buildLanguageInfoSection(),
                  ],
                ),
              ),
      );

  Widget _buildHeaderSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Choose Your Language',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select your preferred language for the Afropeep app. We support multiple Nigerian languages to make your experience more comfortable.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildAvailableLanguagesSection() {
    final availableLanguages =
        _languages.where((lang) => lang['isAvailable'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Languages',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.buttonRadius),
        ...availableLanguages
            .map((language) => _buildLanguageCard(language, true)),
      ],
    );
  }

  Widget _buildComingSoonLanguagesSection() {
    final comingSoonLanguages =
        _languages.where((lang) => lang['isAvailable'] == false).toList();

    if (comingSoonLanguages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coming Soon',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.buttonRadius),
        ...comingSoonLanguages
            .map((language) => _buildLanguageCard(language, false)),
      ],
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> language, bool isAvailable) {
    final isSelected = _selectedLanguage == language['code'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.buttonRadius),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? () => _changeLanguage(language['code']) : null,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                // Flag
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isAvailable ? Colors.transparent : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      language['flag'],
                      style: TextStyle(
                        fontSize: 24,
                        color: isAvailable ? null : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Language Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name'],
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? textPrimary : textLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        language['nativeName'],
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: isAvailable ? textSecondary : textLight,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Selection Indicator
                if (isAvailable) ...[
                  if (_isSaving && isSelected)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  else if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageInfoSection() => Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: primaryColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Language Support',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.buttonRadius),
            _buildInfoItem(
              '🇳🇬 Nigerian languages are prioritized for local users',
            ),
            _buildInfoItem(
              '🔄 App restart may be required for full language change',
            ),
            _buildInfoItem(
              '📱 More languages will be added based on user demand',
            ),
            _buildInfoItem('🌍 Help us translate by sending feedback'),
          ],
        ),
      );

  Widget _buildInfoItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textSecondary,
            height: 1.4,
          ),
        ),
      );
}
