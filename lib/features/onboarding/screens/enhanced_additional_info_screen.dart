import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../widgets/afropeep_height_dropdown.dart';

class EnhancedAdditionalInfoScreen extends StatefulWidget {
  const EnhancedAdditionalInfoScreen({super.key});

  @override
  State<EnhancedAdditionalInfoScreen> createState() =>
      _EnhancedAdditionalInfoScreenState();
}

class _EnhancedAdditionalInfoScreenState
    extends State<EnhancedAdditionalInfoScreen> {
  // Afropeep theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  // Form state
  String _heightFtIn = HeightData.defaultHeightFtIn;
  int _heightCm = HeightData.defaultHeightCm;
  String _platformPurpose = 'Dating & Romance'; // Default to Dating
  String _relationshipIntent = '';
  String _professionalFocus = ''; // For networking users
  String _socialInterests = ''; // For friendship users
  String _education = '';
  String _religion = '';
  String _primaryLanguage = ''; // Changed from List<String> _languages
  String _customLanguage = ''; // For when user selects "Other"
  String _drinkingPreference = '';
  String _smokingPreference = '';

  // Text controller for custom language input
  final TextEditingController _customLanguageController =
      TextEditingController();

  // Platform purpose options - what brings users to Afropeep
  final List<Map<String, dynamic>> _platformPurposeOptions = [
    {
      'label': 'Dating & Romance',
      'value': 'Dating & Romance',
      'icon': Icons.favorite,
      'description': 'Looking for romantic connections and relationships',
      'color': Colors.red.shade400,
    },
    {
      'label': 'Friendship & Social',
      'value': 'Friendship & Social',
      'icon': Icons.people,
      'description': 'Making new friends and expanding social circles',
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Professional Networking',
      'value': 'Professional Networking',
      'icon': Icons.business_center,
      'description': 'Career connections and business opportunities',
      'color': Colors.green.shade400,
    },
    {
      'label': 'All of the Above',
      'value': 'All of the Above',
      'icon': Icons.explore,
      'description': 'Open to dating, friendship, and networking',
      'color': Colors.purple.shade400,
    },
  ];

  final List<Map<String, dynamic>> _relationshipIntentOptions = [
    {
      'label': 'Looking for marriage',
      'value': 'Marriage',
      'icon': Icons.church,
      'description': 'Ready to settle down and start a family',
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Serious relationship',
      'value': 'Serious',
      'icon': Icons.favorite,
      'description': 'Want to build something meaningful and lasting',
      'color': Colors.red.shade400,
    },
    {
      'label': 'Long-term relationship',
      'value': 'Long-term',
      'icon': Icons.favorite_border,
      'description': 'Looking for committed partnership',
      'color': Colors.pink.shade400,
    },
    {
      'label': 'Dating to see where it goes',
      'value': 'Open',
      'icon': Icons.explore,
      'description': 'Open to different possibilities',
      'color': Colors.green.shade400,
    },
    {
      'label': 'Casual dating',
      'value': 'Casual',
      'icon': Icons.coffee_outlined,
      'description': 'Keeping things light and fun',
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Just exploring',
      'value': 'Exploring',
      'icon': Icons.help_outline,
      'description': 'New to dating apps, seeing what\'s out there',
      'color': Colors.grey.shade400,
    },
    {
      'label': 'Not sure yet',
      'value': 'Not sure yet',
      'icon': Icons.help_outline,
      'description': 'Still figuring out what I want',
      'color': Colors.grey.shade500,
    },
  ];

  // Professional focus options for networking users
  final List<Map<String, dynamic>> _professionalFocusOptions = [
    {
      'label': 'Business Development',
      'value': 'Business Development',
      'icon': Icons.trending_up,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Career Mentorship',
      'value': 'Career Mentorship',
      'icon': Icons.school,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Industry Connections',
      'value': 'Industry Connections',
      'icon': Icons.business,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Startup Collaboration',
      'value': 'Startup Collaboration',
      'icon': Icons.lightbulb,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Investment Opportunities',
      'value': 'Investment Opportunities',
      'icon': Icons.attach_money,
      'color': Colors.teal.shade400,
    },
    {
      'label': 'Skill Exchange',
      'value': 'Skill Exchange',
      'icon': Icons.swap_horiz,
      'color': Colors.indigo.shade400,
    },
  ];

  // Social interests options for friendship users
  final List<Map<String, dynamic>> _socialInterestsOptions = [
    {
      'label': 'Activity Partners',
      'value': 'Activity Partners',
      'icon': Icons.sports_soccer,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Study Groups',
      'value': 'Study Groups',
      'icon': Icons.menu_book,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Social Events',
      'value': 'Social Events',
      'icon': Icons.celebration,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Travel Companions',
      'value': 'Travel Companions',
      'icon': Icons.flight,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Hobby Groups',
      'value': 'Hobby Groups',
      'icon': Icons.palette,
      'color': Colors.pink.shade400,
    },
    {
      'label': 'Support Network',
      'value': 'Support Network',
      'icon': Icons.group,
      'color': Colors.teal.shade400,
    },
  ];

  final List<Map<String, dynamic>> _educationOptions = [
    {
      'label': 'High School',
      'value': 'High School',
      'icon': Icons.school,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Some University',
      'value': 'Some University',
      'icon': Icons.school_outlined,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Bachelor\'s Degree',
      'value': 'Bachelor\'s Degree',
      'icon': Icons.school,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Master\'s Degree',
      'value': 'Master\'s Degree',
      'icon': Icons.school,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'PhD/Doctorate',
      'value': 'PhD/Doctorate',
      'icon': Icons.school,
      'color': Colors.red.shade400,
    },
    {
      'label': 'Professional Certification',
      'value': 'Professional Certification',
      'icon': Icons.work,
      'color': Colors.indigo.shade400,
    },
    {
      'label': 'Trade/Vocational School',
      'value': 'Trade/Vocational School',
      'icon': Icons.build,
      'color': Colors.teal.shade400,
    },
  ];

  final List<Map<String, dynamic>> _religionOptions = [
    {
      'label': 'Christianity',
      'value': 'Christianity',
      'icon': Icons.church,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Islam',
      'value': 'Islam',
      'icon': Icons.mosque,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Traditional African Religion',
      'value': 'Traditional African Religion',
      'icon': Icons.nature_people,
      'color': Colors.brown.shade400,
    },
    {
      'label': 'Other',
      'value': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.grey.shade400,
    },
    {
      'label': 'Spiritual but not religious',
      'value': 'Spiritual but not religious',
      'icon': Icons.self_improvement,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Not religious',
      'value': 'Not religious',
      'icon': Icons.remove_circle_outline,
      'color': Colors.orange.shade400,
    },
  ];

  final List<Map<String, dynamic>> _languageOptions = [
    // Major African Languages - simplified for debugging
    {
      'label': 'English',
      'value': 'English',
      'icon': Icons.language,
      'color': Colors.blue.shade400,
    },
    {
      'label': 'Arabic',
      'value': 'Arabic',
      'icon': Icons.language,
      'color': Colors.green.shade400,
    },
    {
      'label': 'French',
      'value': 'French',
      'icon': Icons.language,
      'color': Colors.purple.shade400,
    },
    {
      'label': 'Portuguese',
      'value': 'Portuguese',
      'icon': Icons.language,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Swahili',
      'value': 'Swahili',
      'icon': Icons.language,
      'color': Colors.teal.shade400,
    },

    // Other option - prominently placed
    {
      'label': 'Other (Type your language)',
      'value': 'Other',
      'icon': Icons.edit,
      'color': Colors.grey.shade500,
    },

    // Popular African Languages
    {
      'label': 'Yoruba',
      'value': 'Yoruba',
      'icon': Icons.language,
      'color': Colors.red.shade400,
    },
    {
      'label': 'Igbo',
      'value': 'Igbo',
      'icon': Icons.language,
      'color': Colors.indigo.shade400,
    },
    {
      'label': 'Hausa',
      'value': 'Hausa',
      'icon': Icons.language,
      'color': Colors.brown.shade400,
    },
    {
      'label': 'Amharic',
      'value': 'Amharic',
      'icon': Icons.language,
      'color': Colors.deepOrange.shade400,
    },
    {
      'label': 'Zulu',
      'value': 'Zulu',
      'icon': Icons.language,
      'color': Colors.red.shade600,
    },
    {
      'label': 'Xhosa',
      'value': 'Xhosa',
      'icon': Icons.language,
      'color': Colors.purple.shade600,
    },
    {
      'label': 'Afrikaans',
      'value': 'Afrikaans',
      'icon': Icons.language,
      'color': Colors.orange.shade600,
    },
    {
      'label': 'Somali',
      'value': 'Somali',
      'icon': Icons.language,
      'color': Colors.blueGrey.shade400,
    },
    {
      'label': 'Oromo',
      'value': 'Oromo',
      'icon': Icons.language,
      'color': Colors.lightGreen.shade400,
    },
  ];

  final List<Map<String, dynamic>> _drinkingOptions = [
    {
      'label': 'Never',
      'value': 'Never',
      'icon': Icons.block,
      'color': Colors.red.shade400,
    },
    {
      'label': 'Rarely',
      'value': 'Rarely',
      'icon': Icons.remove_circle_outline,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Socially',
      'value': 'Socially',
      'icon': Icons.people,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Regularly',
      'value': 'Regularly',
      'icon': Icons.local_bar,
      'color': Colors.blue.shade400,
    },
  ];

  final List<Map<String, dynamic>> _smokingOptions = [
    {
      'label': 'Never',
      'value': 'Never',
      'icon': Icons.smoke_free,
      'color': Colors.green.shade400,
    },
    {
      'label': 'Rarely',
      'value': 'Rarely',
      'icon': Icons.remove_circle_outline,
      'color': Colors.orange.shade400,
    },
    {
      'label': 'Socially',
      'value': 'Socially',
      'icon': Icons.people,
      'color': Colors.yellow.shade600,
    },
    {
      'label': 'Regularly',
      'value': 'Regularly',
      'icon': Icons.smoking_rooms,
      'color': Colors.red.shade400,
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;

    if (data != null && data.height > 0) {
      _heightCm = data.height.round();
      final String? ftIn = HeightData.getFtInFromCm(_heightCm);
      if (ftIn != null) {
        _heightFtIn = ftIn;
      }
    }

    if (data == null) return;

    // Map controller value to display value
    String displayValue;
    switch (data.lookingFor) {
      case 'Dating':
        displayValue = 'Dating & Romance';
        break;
      case 'Friendship':
        displayValue = 'Friendship & Social';
        break;
      case 'Networking':
        displayValue = 'Professional Networking';
        break;
      case 'Mixed':
        displayValue = 'All of the Above';
        break;
      default:
        displayValue = 'Dating & Romance';
    }
    _platformPurpose = displayValue;
    _relationshipIntent = data.relationshipIntent;
    _education = data.education ?? '';
    _religion = data.religion;

    // Handle primary language - check if it's in our predefined list
    if (data.languages.isNotEmpty) {
      final controllerLanguage = data.languages.first;
      final isInPredefinedList = _languageOptions
          .any((option) => option['value'] == controllerLanguage);

      if (isInPredefinedList) {
        _primaryLanguage = controllerLanguage;
      } else {
        // It's a custom language
        _primaryLanguage = 'Other';
        _customLanguage = controllerLanguage;
        _customLanguageController.text = controllerLanguage;
      }
    }

    _drinkingPreference = data.drinkingPreference;
    _smokingPreference = data.smokingPreference;
  }

  int _getCompletedFieldsCount() {
    int count = 0;
    if (_heightCm > 0) count++;
    if (_platformPurpose.isNotEmpty) count++;

    // Conditional fields based on platform purpose
    if (_isDatingUser() && _relationshipIntent.isNotEmpty) count++;
    if (_isNetworkingUser() && _professionalFocus.isNotEmpty) count++;
    if (_isFriendshipUser() && _socialInterests.isNotEmpty) count++;

    // Common fields
    if (_education.isNotEmpty) count++;

    // Language field - check if primary language is selected and if "Other", check custom language
    if (_primaryLanguage.isNotEmpty &&
        (_primaryLanguage != 'Other' || _customLanguage.isNotEmpty)) {
      count++;
    }

    // Religion only for dating users
    if ((_isDatingUser() || _platformPurpose == 'All of the Above') &&
        _religion.isNotEmpty) {
      count++;
    }

    return count;
  }

  int _getTotalFieldsCount() {
    int total = 3; // Height, Platform Purpose, Education always required

    // Add conditional fields based on platform purpose
    if (_isDatingUser()) total += 2; // Relationship Intent + Religion
    if (_isNetworkingUser()) total += 1; // Professional Focus
    if (_isFriendshipUser()) total += 1; // Social Interests
    if (_platformPurpose == 'All of the Above') {
      total += 2; // All conditional fields
    }

    total += 1; // Languages always required

    return total;
  }

  bool _isDatingUser() =>
      _platformPurpose == 'Dating & Romance' ||
      _platformPurpose == 'All of the Above';

  bool _isNetworkingUser() =>
      _platformPurpose == 'Professional Networking' ||
      _platformPurpose == 'All of the Above';

  bool _isFriendshipUser() =>
      _platformPurpose == 'Friendship & Social' ||
      _platformPurpose == 'All of the Above';

  String _getEducationSubtitle() {
    if (_isNetworkingUser()) {
      return 'Professional background for networking';
    } else if (_isFriendshipUser()) {
      return 'Educational background helps find like-minded friends';
    } else {
      return 'Your educational background';
    }
  }

  String _getLanguageSubtitle() {
    if (_isNetworkingUser()) {
      return 'Language for professional communication across Africa';
    } else if (_isFriendshipUser()) {
      return 'Your main language - Africa has over 2000 languages!';
    } else {
      return 'Select your primary language - Africa is beautifully diverse!';
    }
  }

  @override
  void dispose() {
    _customLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final completedFields = _getCompletedFieldsCount();
    final totalFields = _getTotalFieldsCount();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          _buildHeader(isTablet, completedFields, totalFields),

          SizedBox(height: isTablet ? 32 : 24),

          // Info card explaining importance
          // Optional step indicator - Industry best practice (progressive disclosure)
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: afropeepGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: afropeepGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: afropeepGreen,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This step is optional',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: afropeepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can skip this and complete it later in your profile settings. Adding more details helps us find better matches!',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 14 : 12,
                          color: textDarkBrown,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          _buildInfoCard(
            'Why we ask for this information',
            'These details help us find better matches and show you to people looking for the same things. Your information is private and secure.',
            Icons.info_outline,
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Height Section
          _buildSectionHeader('Height', 'Height preferences matter in dating'),
          SizedBox(height: isTablet ? 16 : 12),
          AfropeepHeightDropdown(
            initialHeightFtIn: _heightFtIn,
            initialHeightCm: _heightCm,
            onChanged: (heightFtIn, heightCm) {
              setState(() {
                _heightFtIn = heightFtIn;
                _heightCm = heightCm;
              });
              context.read<OnboardingBloc>().add(
                    OnboardingHeightFromDropdownUpdated(heightFtIn, heightCm),
                  );
            },
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Platform Purpose Section - What brings you to Afropeep?
          _buildSectionHeader(
            'What brings you to Afropeep?',
            'Help us understand how to serve you better',
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildPlatformPurposeDropdown(),

          // Show relationship intent only for dating users
          if (_isDatingUser()) ...[
            SizedBox(height: isTablet ? 32 : 24),

            // Relationship Intent Section
            _buildSectionHeader(
              'Relationship goals',
              'What are you hoping to find romantically?',
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildGenericDropdown(
              value: _relationshipIntent,
              options: _relationshipIntentOptions,
              hint: 'Select your relationship goals',
              onChanged: (value) {
                setState(() {
                  _relationshipIntent = value;
                });
                context.read<OnboardingBloc>().add(
                      OnboardingRelationshipIntentUpdated(value),
                    );
              },
            ),
          ],

          // Show networking-specific sections for networking users
          if (_isNetworkingUser()) ...[
            SizedBox(height: isTablet ? 32 : 24),

            // Professional Focus Section
            _buildSectionHeader(
              'Professional Focus',
              'What type of professional connections are you seeking?',
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildGenericDropdown(
              value: _professionalFocus,
              options: _professionalFocusOptions,
              hint: 'Select your professional focus',
              onChanged: (value) {
                setState(() {
                  _professionalFocus = value;
                });
                // Save to controller if method exists
              },
            ),
          ],

          // Show friendship-specific sections for friendship users
          if (_isFriendshipUser()) ...[
            SizedBox(height: isTablet ? 32 : 24),

            // Social Interests Section
            _buildSectionHeader(
              'Social Interests',
              'What kind of friendships are you looking for?',
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildGenericDropdown(
              value: _socialInterests,
              options: _socialInterestsOptions,
              hint: 'Select your social interests',
              onChanged: (value) {
                setState(() {
                  _socialInterests = value;
                });
                // Save to controller if method exists
              },
            ),
          ],

          SizedBox(height: isTablet ? 32 : 24),

          // Education Section - Show for all users but with different context
          _buildSectionHeader('Education', _getEducationSubtitle()),
          SizedBox(height: isTablet ? 16 : 12),
          _buildGenericDropdown(
            value: _education,
            options: _educationOptions,
            hint: 'Select your education level',
            onChanged: (value) {
              setState(() {
                _education = value;
              });
              context.read<OnboardingBloc>().add(
                    OnboardingEducationUpdated(value),
                  );
            },
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Religion Section - Show mainly for dating users, optional for others
          if (_isDatingUser() || _platformPurpose == 'All of the Above') ...[
            _buildSectionHeader(
              'Faith & Religion',
              'Important for many Nigerian relationships',
            ),
            SizedBox(height: isTablet ? 16 : 12),
            _buildGenericDropdown(
              value: _religion,
              options: _religionOptions,
              hint: 'Select your religion',
              onChanged: (value) {
                setState(() {
                  _religion = value;
                });
                context.read<OnboardingBloc>().add(
                      OnboardingReligionUpdated(value),
                    );
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),
          ],

          // Languages Section - Show for all users
          _buildSectionHeader(
            'Languages',
            'Primary language you speak fluently',
          ),
          Text(
            _getLanguageSubtitle(),
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 14 : 12,
              color: textLightBrown,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildGenericDropdown(
            value: _primaryLanguage,
            options: _languageOptions,
            hint: 'Select your primary language',
            onChanged: (value) {
              setState(() {
                _primaryLanguage = value;
                // Clear custom language if not selecting "Other"
                if (value != 'Other') {
                  _customLanguage = '';
                  _customLanguageController.clear();
                }
              });
              final languageToSave = value == 'Other' ? _customLanguage : value;
              if (languageToSave.isNotEmpty) {
                context.read<OnboardingBloc>().add(
                      OnboardingLanguagesUpdated([languageToSave]),
                    );
              }
            },
          ),

          // Show custom language input when "Other" is selected
          if (_primaryLanguage == 'Other') ...[
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: afropeepGreen, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _customLanguageController,
                decoration: InputDecoration(
                  hintText: 'Enter your language',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: isTablet ? 15 : 13,
                    color: Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isTablet ? 16 : 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.edit,
                      color: afropeepGreen,
                      size: isTablet ? 20 : 18,
                    ),
                  ),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: textDarkBrown,
                ),
                onChanged: (value) {
                  setState(() {
                    _customLanguage = value;
                  });
                  if (value.isNotEmpty) {
                    context.read<OnboardingBloc>().add(
                          OnboardingLanguagesUpdated([value]),
                        );
                  }
                },
              ),
            ),
          ],

          SizedBox(height: isTablet ? 32 : 24),

          // Lifestyle Preferences - Show mainly for dating users
          if (_isDatingUser()) ...[
            _buildSectionHeader(
              'Lifestyle',
              'Optional but helps with compatibility',
            ),
            SizedBox(height: isTablet ? 16 : 12),

            // Drinking
            Text(
              'Drinking',
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),
            const SizedBox(height: 8),
            _buildGenericDropdown(
              value: _drinkingPreference,
              options: _drinkingOptions,
              hint: 'Select drinking preference',
              onChanged: (value) {
                setState(() {
                  _drinkingPreference = value;
                });
                context.read<OnboardingBloc>().add(
                      OnboardingDrinkingPreferenceUpdated(value),
                    );
              },
            ),

            const SizedBox(height: 16),

            // Smoking
            Text(
              'Smoking',
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),
            const SizedBox(height: 8),
            _buildGenericDropdown(
              value: _smokingPreference,
              options: _smokingOptions,
              hint: 'Select smoking preference',
              onChanged: (value) {
                setState(() {
                  _smokingPreference = value;
                });
                context.read<OnboardingBloc>().add(
                      OnboardingSmokingPreferenceUpdated(value),
                    );
              },
            ),

            SizedBox(height: isTablet ? 48 : 32),
          ],

          // Simple progress indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: afropeepGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: afropeepGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: afropeepGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress: $completedFields of $totalFields fields completed',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 14 : 12,
                    color: afropeepGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet, int completed, int total) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more about you',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: textDarkBrown,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Help us create better matches for you',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 18 : 16,
              color: textLightBrown,
            ),
          ),
          const SizedBox(height: 16),

          // Progress indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: afropeepGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: afropeepGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: completed / total,
                    backgroundColor: afropeepGreen.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(afropeepGreen),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile completion: $completed of $total sections',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: afropeepGreen,
                        ),
                      ),
                      Text(
                        'Complete profiles get 3x more matches!',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: afropeepGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildInfoCard(String title, String description, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildGenericDropdown({
    required String value,
    required List<Map<String, dynamic>> options,
    required Function(String) onChanged,
    required String hint,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Check if the current value exists in options, if not, use null to show hint
    final validValue =
        value.isNotEmpty && options.any((option) => option['value'] == value)
            ? value
            : null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 48,
        maxHeight: 72,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: afropeepGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              hint,
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 15 : 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: afropeepGreen,
              size: isTablet ? 24 : 20,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isTablet ? 6 : 4,
                    ),
                    child: Row(
                      children: [
                        if (option['icon'] != null) ...[
                          Container(
                            padding: EdgeInsets.all(isTablet ? 6 : 4),
                            decoration: BoxDecoration(
                              color: (option['color'] ?? Colors.grey)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              option['icon'],
                              color: option['color'] ?? Colors.grey,
                              size: isTablet ? 18 : 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            option['label'],
                            style: GoogleFonts.montserrat(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: textDarkBrown,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: textDarkBrown,
          ),
        ),
        SizedBox(height: isTablet ? 6 : 4),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 14 : 12,
            color: textLightBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformPurposeDropdown() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 48,
        maxHeight: 72,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: afropeepGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _platformPurpose,
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: afropeepGreen,
              size: isTablet ? 24 : 20,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
          items: _platformPurposeOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isTablet ? 6 : 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 6 : 4),
                          decoration: BoxDecoration(
                            color: (option['color'] as Color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            option['icon'],
                            color: option['color'],
                            size: isTablet ? 18 : 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option['label'],
                            style: GoogleFonts.montserrat(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: textDarkBrown,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _platformPurpose = value;
              });
              String controllerValue;
              switch (value) {
                case 'Dating & Romance':
                  controllerValue = 'Dating';
                  break;
                case 'Friendship & Social':
                  controllerValue = 'Friendship';
                  break;
                case 'Professional Networking':
                  controllerValue = 'Networking';
                  break;
                case 'All of the Above':
                  controllerValue = 'Mixed';
                  break;
                default:
                  controllerValue = 'Dating';
              }
              context.read<OnboardingBloc>().add(
                    OnboardingLookingForUpdated(controllerValue),
                  );
            }
          },
        ),
      ),
    );
  }
}
