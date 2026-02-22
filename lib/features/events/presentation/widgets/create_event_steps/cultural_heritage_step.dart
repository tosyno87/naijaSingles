import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class CulturalHeritageStep extends StatefulWidget {
  const CulturalHeritageStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<CulturalHeritageStep> createState() => _CulturalHeritageStepState();
}

class _CulturalHeritageStepState extends State<CulturalHeritageStep> {
  late TextEditingController _dressCodeController;

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
    _dressCodeController = TextEditingController(
      text: widget.eventData.metadata['dressCode'] ?? '',
    );
  }

  @override
  void dispose() {
    _dressCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Event Details'),
            const SizedBox(height: 8),
            Text(
              'Set additional details for your event',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            _buildAgeGroupSelector(),
            const SizedBox(height: 20),
            _buildDressCodeField(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      );

  Widget _buildAgeGroupSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age Group',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Who is this event for? (Optional)',
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
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.eventData.metadata['ageGroup'],
                hint: Text(
                  'Select age group (optional)',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppColors.primaryGreen.withValues(alpha: 0.7),
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
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                isExpanded: true,
                dropdownColor: AppColors.backgroundColor,
                items: _ageGroups
                    .map(
                      (ageGroup) => DropdownMenuItem<String>(
                        value: ageGroup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _getAgeGroupIcon(ageGroup),
                                color: AppColors.primaryGreen,
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
                      ),
                    )
                    .toList(),
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

  Widget _buildDressCodeField() => Column(
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
                color: AppColors.primaryGreen.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.primaryGreen.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      );

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
