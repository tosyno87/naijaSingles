import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class CulturalHeritageStep extends StatefulWidget {
  final EventCreationData eventData;

  const CulturalHeritageStep({
    Key? key,
    required this.eventData,
  }) : super(key: key);

  @override
  State<CulturalHeritageStep> createState() => _CulturalHeritageStepState();
}

class _CulturalHeritageStepState extends State<CulturalHeritageStep> {
  late TextEditingController _culturalSignificanceController;
  late TextEditingController _dressCodeController;

  // Cultural heritage options
  final List<String> _culturalHeritages = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Swahili',
    'Akan',
    'Zulu',
    'Xhosa',
    'Amhara',
    'Oromo',
    'Mixed Heritage',
    'Diaspora',
    'Open to All Cultures',
  ];

  final List<String> _languages = [
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
    'Swahili',
    'French',
    'Portuguese',
    'Arabic',
    'Amharic',
    'Zulu',
    'Xhosa',
  ];

  final List<String> _ageGroups = [
    'All Ages Welcome',
    'Adults Only (18+)',
    'Young Adults (18-35)',
    'Elders & Adults (35+)',
    'Youth Focused (18-25)',
    'Family Friendly',
  ];

  @override
  void initState() {
    super.initState();
    _culturalSignificanceController = TextEditingController(
      text: widget.eventData.metadata['culturalSignificance'] ?? '',
    );
    _dressCodeController = TextEditingController(
      text: widget.eventData.metadata['dressCode'] ?? '',
    );
  }

  @override
  void dispose() {
    _culturalSignificanceController.dispose();
    _dressCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cultural Heritage & Context'),
          const SizedBox(height: 8),
          Text(
            'Help attendees understand the cultural significance and requirements of your event',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),
          _buildCulturalHeritageSelector(),
          const SizedBox(height: 20),
          _buildLanguageRequirements(),
          const SizedBox(height: 20),
          _buildAgeGroupSelector(),
          const SizedBox(height: 20),
          _buildCulturalSignificanceField(),
          const SizedBox(height: 20),
          _buildDressCodeField(),
          const SizedBox(height: 20),
          _buildCulturalTemplates(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(
          Icons.celebration,
          color: const Color(0xFF008037),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalHeritageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Cultural Heritage *',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What cultural community is this event primarily for?',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.eventData.metadata['culturalHeritage'] ?? null,
              hint: Text(
                'Select cultural heritage',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF008037).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF008037),
                size: 24,
              ),
              isExpanded: true,
              dropdownColor: AppColors.backgroundColor,
              items: _culturalHeritages.map((heritage) {
                return DropdownMenuItem<String>(
                  value: heritage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getHeritageIcon(heritage),
                          color: const Color(0xFF008037),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          heritage,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.eventData.metadata['culturalHeritage'] = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language Requirements',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What languages will be used at this event?',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((language) {
            final isSelected =
                (widget.eventData.metadata['languages'] as List<String>? ?? [])
                    .contains(language);
            return GestureDetector(
              onTap: () {
                setState(() {
                  final languages = List<String>.from(
                      widget.eventData.metadata['languages'] ?? []);
                  if (isSelected) {
                    languages.remove(language);
                  } else {
                    languages.add(language);
                  }
                  widget.eventData.metadata['languages'] = languages;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF008037).withOpacity(0.1)
                      : AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF008037)
                        : const Color(0xFF008037).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  language,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: isSelected
                        ? const Color(0xFF008037)
                        : const Color(0xFF333333),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Age Group *',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Who is this event designed for?',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.eventData.metadata['ageGroup'] ?? null,
              hint: Text(
                'Select age group',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF008037).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF008037),
                size: 24,
              ),
              isExpanded: true,
              dropdownColor: AppColors.backgroundColor,
              items: _ageGroups.map((ageGroup) {
                return DropdownMenuItem<String>(
                  value: ageGroup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getAgeGroupIcon(ageGroup),
                          color: const Color(0xFF008037),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ageGroup,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: const Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.eventData.metadata['ageGroup'] = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalSignificanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultural Significance',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Why is this event important to the cultural community?',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _culturalSignificanceController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (value) {
            widget.eventData.metadata['culturalSignificance'] = value;
          },
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            hintText:
                'e.g., "This event celebrates our traditional harvest festival and brings together community members to honor our ancestors and share cultural knowledge..."',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF008037).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF008037).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDressCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dress Code & Attire',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What should attendees wear?',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dressCodeController,
          maxLines: 2,
          maxLength: 200,
          onChanged: (value) {
            widget.eventData.metadata['dressCode'] = value;
          },
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            hintText:
                'e.g., "Traditional attire encouraged", "Smart casual", "Formal wear required"',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF008037).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF008037).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalTemplates() {
    final templates = [
      {
        'name': 'Traditional Wedding Ceremony',
        'icon': Icons.favorite,
        'description': 'Celebrate cultural wedding traditions',
        'heritage': 'Mixed Heritage',
        'ageGroup': 'All Ages Welcome',
      },
      {
        'name': 'Cultural Food Festival',
        'icon': Icons.restaurant,
        'description': 'Share traditional cuisine and recipes',
        'heritage': 'Open to All Cultures',
        'ageGroup': 'Family Friendly',
      },
      {
        'name': 'Language Exchange Event',
        'icon': Icons.translate,
        'description': 'Practice African languages together',
        'heritage': 'Diaspora',
        'ageGroup': 'Adults Only (18+)',
      },
      {
        'name': 'Professional Networking',
        'icon': Icons.business,
        'description': 'Connect African professionals',
        'heritage': 'Open to All Cultures',
        'ageGroup': 'Adults Only (18+)',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with a cultural event template',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: templates.map((template) {
            return GestureDetector(
              onTap: () => _applyTemplate(template),
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF008037).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      template['icon'] as IconData,
                      color: const Color(0xFF008037),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template['name'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template['description'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      widget.eventData.metadata['culturalHeritage'] = template['heritage'];
      widget.eventData.metadata['ageGroup'] = template['ageGroup'];
      widget.eventData.category = 'Cultural Events';
    });
  }

  IconData _getHeritageIcon(String heritage) {
    switch (heritage) {
      case 'Yoruba':
      case 'Igbo':
      case 'Hausa':
      case 'Fulani':
        return Icons.flag;
      case 'Swahili':
      case 'Akan':
        return Icons.public;
      case 'Zulu':
      case 'Xhosa':
        return Icons.terrain;
      case 'Amhara':
      case 'Oromo':
        return Icons.terrain;
      case 'Mixed Heritage':
        return Icons.merge;
      case 'Diaspora':
        return Icons.flight;
      case 'Open to All Cultures':
        return Icons.diversity_3;
      default:
        return Icons.celebration;
    }
  }

  IconData _getAgeGroupIcon(String ageGroup) {
    switch (ageGroup) {
      case 'All Ages Welcome':
        return Icons.family_restroom;
      case 'Adults Only (18+)':
        return Icons.person;
      case 'Young Adults (18-35)':
        return Icons.people;
      case 'Elders & Adults (35+)':
        return Icons.elderly;
      case 'Youth Focused (18-25)':
        return Icons.school;
      case 'Family Friendly':
        return Icons.child_care;
      default:
        return Icons.group;
    }
  }
}
